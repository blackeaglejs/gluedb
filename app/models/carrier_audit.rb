class CarrierAudit
	include Mongoid::Document
	attr_accessor :submitted_by

	field :active_start, type: Date
	field :active_end, type: Date
	field :cutoff_date, type: Date
	field :market, type: String

	has_and_belongs_to_many :carriers

	def select_policies
	end

end

