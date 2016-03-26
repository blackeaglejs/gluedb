require 'spreadsheet'
require 'csv'

class ExcelReportBuilder

  def has_aptc_during_year?(policy)
    # policy.applied_aptc.to_f > 0

    aptcs = policy.versions.map(&:applied_aptc).map{ |x| x.to_f } + [ policy.applied_aptc.to_f ]
    aptcs.uniq.any? {|aptc| aptc > 0}
  end

  def aptc_report
    workbook = Spreadsheet::Workbook.new
    sheet = workbook.create_worksheet :name => '2014 QHP Policies'
    index = 1
    @carriers = Carrier.all.inject({}){|hash, carrier| hash[carrier.id] = carrier.name; hash}


    columns = ['PolicyId', 'HbxId', 'Full name','Carrier', 'Hios Plan ID', 'Plan Year', 'Plan Name', 'Coverage Start', 'Coverage End']
    12.times {|i| columns += ["#{i+1}/2014 Premium", "#{i+1}/2014 APTC"]}

    sheet.row(0).concat columns
    count = 0

    policies_by_subscriber.each do |id, policies|
      count += 1

      if (count % 100) == 0
        puts "looked at #{count} records..."
      end

      policies.each do |policy|
        begin
          if has_aptc_during_year?(policy)

            next if policy.canceled?
            active_enrollees = policy.enrollees.reject{|en| en.canceled?}
            next if active_enrollees.empty?

            next if rejected_policy?(policy)
            next unless policy.belong_to_authority_member?
            next if policy.subscriber.coverage_end.present? && (policy.subscriber.coverage_end < policy.subscriber.coverage_start)


            irs_input = Generators::Reports::IrsInputBuilder.new(policy)

            irs_input.carrier_hash = @carriers
            irs_input.process

            sheet.row(index).concat build_aptc_row(policy, irs_input.notice)
            index += 1

            if (index % 50) == 0
              puts "found....#{index}"
            end
          end
        rescue Exception => e
          puts e.to_s
        end
      end
    end

    workbook.write "#{Rails.root.to_s}/aptc_report_2015_with_version_lookup.xls"
  end

  def build_aptc_row(policy, notice)
    data = [
      policy.id,
      policy.subscriber.hbx_member_id,
      policy.subscriber.person.full_name,
      @carriers[policy.plan.carrier_id],
      policy.plan.hios_plan_id,
      policy.plan.year,
      policy.plan.name,
      notice.recipient.coverage_start_date,
      notice.recipient.coverage_termination_date
    ]

    data + (1..12).inject([]) do |data, index|
      monthly_premium = notice.monthly_premiums.detect{|p| p.serial == index}
      data << (monthly_premium.blank? ? nil : monthly_premium.premium_amount)
      data << (monthly_premium.blank? ? nil :  monthly_premium.monthly_aptc)
    end
  end


  def get_aptc_maintainance_details
    workbook = Spreadsheet::Workbook.new
    sheet = workbook.create_worksheet :name => 'Multi Assisted QHP'
    index = 1
    count = 0

    columns = ['Integrated Case', 'Primary', 'Address Line 1', 'Apt/Ste', 'Address Line 2', 'City', 'State', 'Zip', 'APTC', 'Last Update']
 
    sheet.row(0).concat columns

    CSV.foreach("#{Rails.root}/December Terms - full list.csv") do |row|

      next if row[0].strip == 'Integrated Case'

      e_case_id = row[0].strip
      full_name = row[1].strip

      puts full_name.inspect

      # people = Person.where(name_full: full_name)

      app_group = ApplicationGroup.where(e_case_id: e_case_id)

      # if people.count > 1
      #   count += 1
      #   # puts "----- zero or more than 1"
      # end

      if app_group.count == 1
        count += 1
        # puts "----- zero or more than 1"
      end

      sheet.row(index).concat row.split(',')
      index += 1
    end  
    puts count                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
    # workbook.write "#{Rails.root.to_s}/#{file}"
  end

  def build_1095a_report
    workbook = Spreadsheet::Workbook.new
    sheet = workbook.create_worksheet :name => 'Unassisted QHP'
    index = 0
    failed = 0
    @carriers = Carrier.all.inject({}){|hash, carrier| hash[carrier.id] = carrier.name; hash}

    columns = ['POLICY ID']
    5.times {|i| columns += ["NAME#{i+1}", "SSN#{i+1}", "DOB#{i+1}", "BEGINDATE#{i+1}", "ENDDATE#{i+1}"]}
    columns += ['ISSUER NAME']
    12.times {|i| columns += ["PREMIUM#{i+1}", "SLCSP#{i+1}", "APTC#{i+1}"]}
    sheet.row(index).concat columns

    # book = Spreadsheet.open "#{Rails.root}/MergedExclusionPolicyIdReconSet20160114.xls"
    # skip_list = book.worksheets.first.inject([]){|data, row| data << row[0].to_s.strip.to_i}.compact

    book = Spreadsheet.open "#{Rails.root}/EXCLUSION_2015_H41_EOY_201602111545.xls"
    skip_list = book.worksheets.first.inject([]){|data, row| data << row[0].to_s.strip.to_i}.compact

    # skip_list = []

    # book = Spreadsheet.open "#{Rails.root}/INCLUSION_CF_AETNA_DUPE_OVERLAP_UPDATES_20160201-0800.xls"
    # inclusion_list = book.worksheets.first.inject([]){|data, row| data << row[0].to_s.strip.to_i}.compact

    # puts inclusion_list.inspect

    # kaiser_plans = Plan.where(carrier_id: "53e67210eb899a460300000d", year: 2015).map(&:id)

    kaiser_plans = []
    current = 0

    responsible_party = []
    missing_enrollees = []
    non_authority = []

    policies_by_subscriber.each do |row, policies|
    # inclusion_list.each do |policy_id|
      # policies = [Policy.find(policy_id)].compact

      policies.each do |policy|
        begin


          current += 1

          if current % 1000 == 0
            puts "at #{current}"
          end

          # next unless policy.multi_aptc?

          # if policy.responsible_party_id.present?
          #   responsible_party << policy.id
          #   next
          # end

          next if skip_list.include?(policy.id)
          # next unless (policy.applied_aptc > 0 || policy.multi_aptc?)

          next unless policy.belong_to_authority_member?

          # next unless kaiser_plans.include?(policy.plan_id)
          next if policy.subscriber.coverage_end.present? && (policy.subscriber.coverage_end < policy.subscriber.coverage_start)
          # next unless (policy.subscriber.coverage_end.present? && (policy.subscriber.coverage_end.end_of_month != policy.subscriber.coverage_end))

          # active_enrollees = policy.enrollees.reject{|en| en.canceled?}
          # if active_enrollees.empty?
          #   missing_enrollees << policy.id
          #   next
          # end

          if rejected_policy?(policy)
            puts "rejected policy #{policy.id}"
            next
          end

          next if policy.canceled?

          next unless policy.responsible_party_id.present?
   

          input_builder = Generators::Reports::IrsInputBuilder.new(policy)
          input_builder.carrier_hash = @carriers
          input_builder.process


          # if policy.responsible_party_id.present?
          #   if responsible_party = Person.where("responsible_parties._id" => Moped::BSON::ObjectId.from_string(policy.responsible_party_id)).first
          #     puts "responsible party #{responsible_party.id} #{policy.id}address attached"          
          #     input_builder.append_recipient_address(responsible_party)
          #     # input_builder.append_recipient(responsible_party)
          #   end
          # end

          @notice = input_builder.notice

          if (@notice.recipient_address.to_s.match(/609 H St NE/i).present? || @notice.recipient_address.to_s.match(/1225 Eye St NW/i).present?)
            puts @notice.recipient_address.to_s
            next
          end

          @data = [ @notice.policy_id ]

          append_coverage_household
          @data += [@notice.issuer_name]
          append_premiums


          index += 1

          if (index % 100) == 0
            puts "found #{index}"
          end

          sheet.row(index).concat @data
        rescue Exception => e
          puts policy.id
          puts e.to_s.inspect
          failed += 1
        end
      end
    end

    puts "failed-----#{failed}"
    puts missing_enrollees.inspect
    puts responsible_party.inspect
    puts non_authority.inspect

    workbook.write "#{Rails.root.to_s}/responsible_party_#{Time.now.strftime("%m_%d_%Y_%H_%M")}.xls"
  end

  def append_covered_member(indiv)
    @data += [indiv.name, indiv.ssn, indiv.dob, indiv.coverage_start_date, indiv.coverage_termination_date]
  end

  def append_coverage_household
    @notice.covered_household.each do |indiv|
      append_covered_member(indiv)
    end
    (5 - @notice.covered_household.size).times{ append_blank_arr(5) }
  end

  def append_blank_arr(size)
    size.times{ @data << '' }
  end

  def append_premiums
    (1..12).each do |index|
      monthly_premium = @notice.monthly_premiums.detect{|p| p.serial == index}
      if monthly_premium.blank?
        append_blank_arr(3)
      else
        @data += [monthly_premium.premium_amount, monthly_premium.premium_amount_slcsp, monthly_premium.monthly_aptc]
      end
    end
  end

  def rejected_policy?(policy)
    edi_transactions = Protocols::X12::TransactionSetEnrollment.where({ "policy_id" => policy.id })
    return true if edi_transactions.size == 1 && edi_transactions.first.aasm_state == 'rejected'
    false
  end

  def policies_by_subscriber
    plans = Plan.where({:metal_level => {"$not" => /catastrophic/i}, :coverage_type => /health/i}).map(&:id)

    p_repo = {}

    p_map = Person.collection.aggregate([{"$unwind"=> "$members"}, {"$project" => {"_id" => 0, member_id: "$members.hbx_member_id", person_id: "$_id"}}])

    p_map.each do |val|
      p_repo[val["member_id"]] = val["person_id"]
    end

    pols = PolicyStatus::Active.between(Date.new(2013,12,31), Date.new(2014,12,31)).results.where({
      :plan_id => {"$in" => plans}, :employer_id => nil
      }).group_by { |p| p_repo[p.subscriber.m_id] }
  end
end