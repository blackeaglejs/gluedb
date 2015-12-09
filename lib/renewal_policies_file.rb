require 'spreadsheet'

class RenewalPoliciesFile

  CALENDER_YEAR = 2015

  def initialize
    @atena_plan_ids = Plan.where(carrier_id: "53e67210eb899a4603000007", year: 2015).map(&:id)
    @catastrophic_plan_ids = Plan.where({:metal_level => /catastrophic/i, year: 2015 }).map(&:id)

    # @alex_policies = []

    # book = Spreadsheet.open "#{Rails.root}/exclude_list.xls"
    # book.worksheets.first.each do |row|
    #   next if row[7] == "POLICY" || row[7].to_s.blank?
    #   @alex_policies << row[7]
    # end

    @invalid_pols = [51123,  51267, 51273, 51530, 51537, 51589, 44084, 45179, 17269, 30022]
    @wrong_ecase_ids = ["2325723", "2324956"]
    #@cv_generator = RenewalCvGenerator.new

    @zrenews = []
  end

  def group_policies_for_noticies(health_policies, dental_policies)
    if health_policies.empty?
      return dental_policies.inject([]) do |data, dental|
        data << [nil , dental]
      end
    else
      policy_groups = health_policies.inject([]) do |data, health|
        member_ids = health.enrollees.map { |x| x.m_id }.sort
        matching_dentail = nil

        dental_policies.each do |dental|
          if dental.enrollees.map { |e| e.m_id }.sort == member_ids
            matching_dentail = dental
            break
          end
        end

        dental_policies.delete(matching_dentail)
        data << [health, matching_dentail]
      end
      policy_groups + dental_policies.map{|dental| [nil, dental]}
    end
  end

  def process

    @hbx_member_id = nil
    current = 0
    count = 0

    policies_by_subscriber.each do |subscriber, policies|

      current += 1

      if current % 1000 == 0
        puts "currently at #{current}"
      end

      #policies.reject!{ |p| p.applied_aptc.to_f > 0 }
      policies = policies_for_year(policies, CALENDER_YEAR)

      timestamp = Time.now.strftime('%Y%m%d%H%M')
      over_30_catastrophic_ids = File.new("catastrophic_renewal_ids_#{timestamp}.txt", "w")

      #policies.reject! { |policy| @alex_policies.include?(policy.id) }
      policies.reject! { |policy| @atena_plan_ids.include?(policy.plan_id) }
      policies.reject! { |policy| @invalid_pols.include?(policy.id) }
      policies.each do |policy|
        if @catastrophic_plan_ids.include?(policy.plan_id) && !all_under_thirty?(policy)
          puts "#{policy._id}"
        end
      end
      policies.reject! { |policy| @catastrophic_plan_ids.include?(policy.plan_id) && !all_under_thirty?(policy) }

      next if policies.empty?
      @hbx_member_id = policies[0].subscriber.person.authority_member.hbx_member_id

      policies = filter_duplicate_policies(policies)

      if policies.empty?
        raise "Got Empty!!!"
      end

      health_policies = policies.select{|policy| policy.coverage_type == 'health' }
      dental_policies = policies.select{|policy| policy.coverage_type == 'dental' }

      #puts "#{health_policies.count},#{dental_policies.count}"


      if health_policies.size > 1
        names = health_policies.inject([]) {|data, pol| data << pol.enrollees.reject {|en| en.canceled? || en.terminated? }.map(&:person).map(&:full_name) }
        if names.uniq.count > 1
          health_policies = health_policies.map(&:id).include?(51338) ? [health_policies.first] : [health_policies.last]
        else
          health_policies = [health_policies.last]
        end
      end

      if dental_policies.size > 1
        names = dental_policies.inject([]) {|data, pol| data << pol.enrollees.reject {|en| en.canceled? || en.terminated? }.map(&:person).map(&:full_name) }
        if names.uniq.count > 1
          puts names.inspect
        end
        dental_policies = [dental_policies.last]
      end

      health_policies.each do |policy|
        if is_assisted?(policy) == true
          health_policies.pop
        else
          next
        end
      end

      timestamp = Time.now.strftime('%Y%m%d%H%M')

      zohebs_renewal_ids = File.new("renewal_ids_#{timestamp}.txt", "w")

      policy_pairs = group_policies_for_noticies(health_policies, dental_policies)
      ids = policy_pairs.flatten.compact.map(&:id)
      #@cv_generator.process(ids)
      count += ids.count
      @zrenews.push(ids)
      zohebs_renewal_ids.puts(@zrenews)
    end
    puts count
  end

  def filter_duplicate_policies(policies)
    policies.group_by{|pol| pol.plan_id}.inject([]) do |data, (key, value)|
      data << value.last
    end
  end

  def policies_by_subscriber
    # plans = Plan.where({:year => 2015 })
    hplans1 = Plan.all.select{|plan| plan.hios_plan_id.match(/-01/)}.map(&:id)
    hplans2 = Plan.all.select{|plan| plan.hios_plan_id.match(/-02/)}.map(&:id)
    hplans3 = Plan.all.select{|plan| plan.hios_plan_id.match(/-03/)}.map(&:id)
    hplans4 = Plan.all.select{|plan| plan.hios_plan_id.match(/-04/)}.map(&:id)
    hplans5 = Plan.all.select{|plan| plan.hios_plan_id.match(/-05/)}.map(&:id)
    hplans6 = Plan.all.select{|plan| plan.hios_plan_id.match(/-06/)}.map(&:id)

    hplans = hplans1 + hplans2 + hplans3 + hplans4 + hplans5 + hplans6

    dplans = Plan.all.select{|plan| plan.hios_plan_id.length==14}.map(&:id)

    plans = hplans + dplans

    p_repo = {}

    p_map = Person.collection.aggregate([{"$unwind"=> "$members"}, {"$project" => {"_id" => 0, member_id: "$members.hbx_member_id", person_id: "$_id"}}])

    p_map.each do |val|
      p_repo[val["member_id"]] = val["person_id"]
    end

    pols = PolicyStatus::Active.between(Date.new(2014,12,31), Date.new(2015,12,31)).results.where({
      :plan_id => {"$in" => plans}, :employer_id => nil
      }).group_by { |p| p_repo[p.subscriber.m_id] }
  end

  def all_under_thirty?(policy)
    policy.enrollees.any? {|e| Ager.new(e.person.authority_member.dob).age_as_of(Date.new(2016,1,1)) >= 30 } ? false : true
  end

  def policies_for_year(policies, year)
    policies.select do  |policy| 
      valid_policy?(policy) && policy.belong_to_year?(year) && policy.belong_to_authority_member?
    end
  end

  def valid_policy?(pol)
    return false if pol.rejected? || pol.has_no_enrollees? || pol.canceled? || pol.is_shop? || pol.terminated?
    true
  end

    def is_assisted?(policy)
    if policy.applied_aptc != 0
      return true
    elsif policy.applied_aptc == 0 and !policy.plan.hios_plan_id.match(/-01/)
      return true
    else
      return false
    end
  end
end