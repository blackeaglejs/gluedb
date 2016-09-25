class CarrierAudit
	include Mongoid::Document
	attr_accessor :submitted_by

	field :active_start, type: Date
	field :active_end, type: Date
	field :cutoff_date, type: Date
	field :market, type: String
	field :chosen_carriers, type: Array

	has_many :carriers
	has_many :plans
	has_many :employers
	has_many :plan_years
	has_many :policies
end

