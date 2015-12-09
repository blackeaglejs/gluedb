## Use the RenewalPoliciesFile.new.process on the console to generate policy IDs for  overage catastrophic policies.
## Those IDs will print straight to console. 
## You can pull these IDs in a text file if desired, just place the file name in on line 8.
## The CSV that's generated will inform you if there is already a 2016 plan selection in Glue and if they have multiple 
## health policies in 2015. If they have multiple 2015 plans you need to manually go into Glue and check whether a plan other
## than the catastrophic one needs to be renewed. 

require 'csv'

policy_ids = []

File.readlines('catastrophic_renewal_ids.txt').map do |line|
  policy_ids.push(line.to_i)
end

def multiple_2015_policies?(person)
	subscriber_policies = person.policies.to_a
	policies_2015 = []
	if subscriber_policies.count > 1
		subscriber_policies.each do |policy|
			if policy.enrollees.first.coverage_start.year == 2015
				if policy.coverage_type != "dental"
					policies_2015.push(policy)
				end
			end
		end
	end
	if policies_2015.count == 0
		return subscriber_policies.count
	else
		return policies_2015.count
	end
end

def any_2016_policies?(person)
	subscriber_policies = person.policies.to_a
	policies_2016 = []
	if subscriber_policies.count > 1
		subscriber_policies.each do |policy|
			if policy.enrollees.first.coverage_start.year == 2016
				if policy.coverage_type == "health"
					policies_2016.push(policy)
				end
			end
		end
	end
	if policies_2016.count > 1
		return "Multiple 2016 Policies"
	elsif policies_2016.count == 1
		return policies_2016.first.plan.name
	elsif policies_2016.count == 0
		return " "
	end
end

CSV.open("catastrophic_over_30.csv", "w") do |csv|
	csv << ["Policy ID", "HBX ID", "Name", "Start Date", "Plan Name", "Enrollee Count", "Number of 2015 Health Policies", "2016 Health Policies"]
	policy_ids.each do |id|
		policy = Policy.find(id)
		next if policy.enrollees.first.coverage_end != nil
		policy_id = policy._id
		subscriber = policy.subscriber.person
		if subscriber == nil
			policy.enrollees.each do |enrollee|
				if enrollee.rel_code == "self"
					subscriber = enrollee.person
				end
			end
		end
		hbx_id = subscriber.try(:authority_member_id)
		name = subscriber.name_full
		start_date = policy.enrollees.first.coverage_start
		plan_name = policy.plan.name
		enrollee_count = policy.enrollees.count
		policy_count = multiple_2015_policies?(subscriber)
		policies_in_2016 = any_2016_policies?(subscriber)
		csv << [policy_id, hbx_id, name, start_date, plan_name, enrollee_count, policy_count, policies_in_2016]
	end
end