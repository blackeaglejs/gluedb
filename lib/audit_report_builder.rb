require 'spreadsheet'
require 'csv'

class AuditReportBuilder

  def qhp_audit_report
    workbook = Spreadsheet::Workbook.new
    sheet = workbook.create_worksheet :name => '2014 QHP Policies'
    index = 1
    @carriers = Carrier.all.inject({}){|hash, carrier| hash[carrier.id] = carrier.name; hash}

    columns = %W(LASTNAME FIRSTNAME MI MEMBERID DOB GENDER DEPENDENTS PLANNAME PLANID METALLEVEL STARTDATE ENDDATE)
    12.times {|i| columns += ["PREMIUM#{i+1}", "APTC#{i+1}"]}

    sheet.row(0).concat columns
    count = 0
    policies_by_subscriber.each do |id, policies|
      policies.each do |policy|
        count += 1
        next if count > 200

        if count % 200 == 0
          puts "processed #{count}"
        end

        begin
          next if policy.subscriber.coverage_end.present? && policy.subscriber.coverage_end < Date.new(2014, 10, 1)
          # next if policy.subscriber.coverage_start >= Date.new(2015, 10, 1)
          next if !valid_policy?(policy)
          irs_input = Generators::Reports::IrsInputBuilder.new(policy)
          irs_input.carrier_hash = @carriers
          irs_input.process
          sheet.row(index).concat build_business_audit_row(policy, irs_input.notice)
          index += 1
        rescue Exception => e
          puts e.to_s
        end
      end
    end

    workbook.write "#{Rails.root.to_s}/audit_report_2014.xls"
  end

  private

  def policies_by_subscriber
    plans = Plan.where({:year => 2014}).map(&:id)    
    p_repo = {}
    p_map = Person.collection.aggregate([{"$unwind"=> "$members"}, {"$project" => {"_id" => 0, member_id: "$members.hbx_member_id", person_id: "$_id"}}])
    p_map.each do |val|
      p_repo[val["member_id"]] = val["person_id"]
    end
    pols = PolicyStatus::Active.between(Date.new(2013,12,31), Date.new(2014,12,31)).results.where({
      :plan_id => {"$in" => plans}, :employer_id => nil
      }).group_by { |p| p_repo[p.subscriber.m_id] }
  end

  def build_business_audit_row(policy, notice)
    person = policy.subscriber.person
    data = [
      person.name_last,
      person.name_first,
      person.name_middle,
      policy.subscriber.hbx_member_id,
      person.authority_member.dob.strftime("%m/%d/%Y"),
      person.authority_member.gender,
      policy.enrollees_sans_subscriber.reject{|member| member.canceled? }.size,
      policy.plan.name,
      policy.plan.hios_plan_id,
      policy.plan.metal_level,
      notice.recipient.coverage_start_date,
      notice.recipient.coverage_termination_date
    ]

    data + (1..12).inject([]) do |data, index|
      monthly_premium = notice.monthly_premiums.detect{|p| p.serial == index}
      data << ((monthly_premium.blank? || index < 10) ? nil : monthly_premium.premium_amount)
      data << ((monthly_premium.blank? || index < 10) ? nil : monthly_premium.monthly_aptc)
    end
  end

  def rejected_policy?(policy)
    edi_transactions = Protocols::X12::TransactionSetEnrollment.where({ "policy_id" => policy.id })
    return true if edi_transactions.size == 1 && edi_transactions.first.aasm_state == 'rejected'
    false
  end

  def valid_policy?(policy)
    return false if policy.canceled?
    active_enrollees = policy.enrollees.reject{|en| en.canceled?}
    return false if active_enrollees.empty? || rejected_policy?(policy) || !policy.belong_to_authority_member?
    return false if policy.subscriber.coverage_end.present? && (policy.subscriber.coverage_end < policy.subscriber.coverage_start)
    true
  end
end

