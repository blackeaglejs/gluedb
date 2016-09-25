class CarrierAuditsController < ApplicationController

	def new
		@carrier_audit = CarrierAudit.new(:submitted_by => current_user.email)
		@carriers = Carrier.all
	end

	def create
		@carrier_audit = CarrierAudit.new(params[:carrier_audit])
		@carrier_audit.active_start = @carrier_audit.cutoff_date.end_of_month
		@carrier_audit.active_end = (@carrier_audit.active_start) + 1.year
		@carrier_audit.carriers = Carrier.where(:_id => {"$in" => params["carrier_ids"]})
		@carrier_audit.save
		if @carrier_audit.market == "individual"
			#@carrier_audit.generate_ivl_audits
		elsif @carrier_audit.market == "shop"
			@carrier_audit.active_start = @carrier_audit.active_end.beginning_of_year
			@carrier_audit.generate_shop_audits
		end
		redirect_to new_carrier_audit_path
	end
end