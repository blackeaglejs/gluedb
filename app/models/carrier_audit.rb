class CarrierAudit
	include Mongoid::Document
	attr_accessor :submitted_by

	field :active_start, type: Date
	field :active_end, type: Date
	field :cutoff_date, type: Date
	field :market, type: String

	has_and_belongs_to_many :carriers

	def select_plans
	  plan_ids = Plan.where(:carrier_id => {"$in" => carrier_ids}).map(&:id)
	  return plan_ids
	end

	def select_employers
	  employer_ids = PlanYear.where(:start_date => {"$gt" => active_start, "$lt" => active_end}).map(&:employer_id)
	  return employer_ids
	end

	def select_shop_policies(active_start,employer_ids,plan_ids)
	  eligible_pols = pols = Policy.where({:enrollees => {"$elemMatch" => {:rel_code => "self",
	  	                                                                   :coverage_start => {"$gt" => active_start}}}, 
	  	                                  :employer_id => {"$in" => employer_ids}, 
	  	                                  :plan_id => {"$in" => plan_ids}}).no_timeout
	  return eligible_pols
	end

	def select_ivl_policies(active_start,plan_ids)
	  start_date = active_start-1.day
	  eligible_pols = pols = Policy.where({:enrollees => {"$elemMatch" => {:rel_code => "self",
	  	                                                                   :coverage_start => {"$gt" => start_date}}}, 
	  	                                  :employer_id => nil, 
	  	                                  :plan_id => {"$in" => plan_ids}}).no_timeout
	  return eligible_pols
	end

	def get_member_ids(policies)
	  m_ids = []
	  policies.each do |policy|
	    if !policy.canceled?
	      policy.enrollees.each do |enrollee|
	      	m_ids << enrollee.m_id
	      end
	    end
	  end
	end

	def current_plan_year(employer)
	  today = Time.now.to_date
	  employer.plan_years.each do |plan_year|
	  	py_start = plan_year.start_date
	  	py_end = plan_year.end_date
	  	date_range = (py_start..py_end)
	  	if date_range.include?(today)
	  	  return plan_year
	  	end
	  end
	end

	def in_current_plan_year?(policy,employer)
	  plan_year = current_plan_year(employer)
	  policy_start_date = policy.subscriber.coverage_start
	  py_start = plan_year.start_date
	  py_end = plan_year.end_date
	  date_range = (py_start..py_end)
	  if date_range.include?(policy_start_date)
	  	return true
	  else
	  	return false
	  end
	end

	def generate_shop_audits
	  plan_ids = select_plans
	  employer_ids = select_employers
	  shop_policies = select_shop_policies(active_start,employer_ids,plan_ids)
	  m_ids = get_member_ids(shop_policies)
	  m_cache = Caches::MemberCache.new(m_ids)

	  Caches::MongoidCache.allocate(Plan)
	  Caches::MongoidCache.allocate(Carrier)
	  Caches::MongoidCache.allocate(Employer)

	  shop_policies.each do |policy|
	  	if !policy.canceled?
	  	  if !(policy.subscriber.coverage_start > active_end)
	  	  	employer = Caches::MongoidCache.lookup(Employer, policy.employer_id) {policy.employer}
	  	  	subscriber_id = policy.subscriber.m_id
	  	  	subscriber_member = m_cache.lookup(subscriber_id)
	  	  	auth_subscriber_id = subscriber_member.person.authority_member_id
	  	  	if auth_subscriber_id == subscriber_id
	  	  	  enrollee_list = policy.enrollees.reject { |en| en.canceled? }
	  	  	  all_ids = enrollee_list.map(&:m_id) | [subscriber_id]
	  	  	  out_f = File.open(File.join("audits", "#{policy._id}_audit.xml"), 'w')
	  	  	  ser = CanonicalVocabulary::MaintenanceSerializer.new(policy,
	  	  	  	                                                   "audit",
	  	  	  	                                                   "notification_only",
	  	  	  	                                                   all_ids,
	  	  	  	                                                   all_ids,
	  	  	  	                                                   { :term_boundry => active_end,
	  	  	  	                                                   	 :member_repo => m_cache })
	  	  	  out_f.write(ser.serialize)
	  	  	  out_f.close
	  	  	end
	  	  end
	  	end
	  end
	end

	def generate_ivl_audits
	  plan_ids = select_plans
	  ivl_policies = select_ivl_policies(active_start,plan_ids)
	  m_ids = get_member_ids(ivl_policies)
	  m_cache = Caches::MemberCache.new(m_ids)

	  Caches::MongoidCache.allocate(Plan)
	  Caches::MongoidCache.allocate(Carrier)
	  Caches::MongoidCache.allocate(Employer)

	  ivl_policies.each do |policy|
	  	if !policy.canceled?
	  	  if !(policy.subscriber.coverage_start > active_end)
	  	  	subscriber_id = policy.subscriber.m_id
	  	  	subscriber_member = m_cache.lookup(subscriber_id)
	  	  	auth_subscriber_id = subscriber_member.person.authority_member_id
	  	  	if auth_subscriber_id == subscriber_id
	  	  	  enrollee_list = policy.enrollees.reject { |en| en.canceled? }
	  	  	  all_ids = enrollee_list.map(&:m_id) | [subscriber_id]
	  	  	  out_f = File.open(File.join("audits", "#{policy._id}_audit.xml"), 'w')
	  	  	  ser = CanonicalVocabulary::MaintenanceSerializer.new(policy,
	  	  	  	                                                   "audit",
	  	  	  	                                                   "notification_only",
	  	  	  	                                                   all_ids,
	  	  	  	                                                   all_ids,
	  	  	  	                                                   { :term_boundry => active_end,
	  	  	  	                                                   	 :member_repo => m_cache }
	  	  	  out_f.write(ser.serialize)
	  	  	  out_f.close
	  	  	end
	  	  end
	  	end
	  end
	end
end

