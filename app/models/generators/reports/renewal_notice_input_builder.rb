module Generators::Reports  
  class RenewalNoticeInputBuilder

    def process(policies, carriers = {})
      @carriers = carriers
      health, dental = policies
      base_policy = health || dental

      if base_policy.subscriber.nil?
        raise 'no subscriber present'
      end

      primary = base_policy.subscriber.person
      return if primary.mailing_address.blank?

      # members = base_policy.enrollees_sans_subscriber.map{|enrollee| enrollee.person.name_full}

      notice = PdfTemplates::RenewalNoticeInput.new
      # notice.covered_individuals = members
      notice.primary_name = primary.name_full
      notice.primary_identifier = primary.authority_member.hbx_member_id

      if health
        notice.health_policy = health.id
        notice.health_plan_current = [carriers[health.plan.carrier_id], health.plan.name].join(" - ")
      end

      if dental
        notice.dental_policy = dental.id
        notice.dental_plan_current = [carriers[dental.plan.carrier_id], dental.plan.name].join(" - ")
      end

      if primary.addresses.empty?
        raise 'subscriber address empty'
      end

      active_enrollees = base_policy.enrollees_sans_subscriber.reject{ |en| en.canceled? || en.terminated? }

      notice = append_address(primary, notice)
      notice = append_taxhousehold(primary, active_enrollees.map(&:person), notice)
      notice = append_health_policy(health, notice) if health
      notice = append_dental_policy(dental, notice) if dental

      notice
    end

    def append_address(primary, notice)
      primary_address = primary.mailing_address
      address = PdfTemplates::NoticeAddress.new
      address.street_1 = primary_address.address_1
      address.street_2 = primary_address.address_2
      address.city = primary_address.city
      address.state = primary_address.state
      address.zip = primary_address.zip
      notice.primary_address = address
      notice
    end

    def append_health_policy(health_policy, notice)
      renewal_policy = health_policy.clone_for_renewal(Date.new(2016, 1, 1))
      if @carriers[renewal_policy.plan.carrier_id]
        notice.health_plan_name = @carriers[renewal_policy.plan.carrier_id] + renewal_policy.plan.name
      else
        notice.health_plan_name = "Carrier missing -" + renewal_policy.plan.name
      end
      begin
        pc = ::Premiums::PolicyCalculator.new
        pc.apply_calculations(renewal_policy)
        notice.health_premium = renewal_policy.pre_amt_tot
      rescue
        notice.health_premium = 0
      end
      notice
    end

    def append_dental_policy(dental_policy, notice)
      renewal_policy = dental_policy.clone_for_renewal(Date.new(2016, 1, 1))
      if @carriers[renewal_policy.plan.carrier_id]
        notice.dental_plan_name = @carriers[renewal_policy.plan.carrier_id] + renewal_policy.plan.name
      else
        notice.health_plan_name = "Carrier missing -" + renewal_policy.plan.name
      end
      binding.pry
      begin
        pc = ::Premiums::PolicyCalculator.new
        pc.apply_calculations(renewal_policy)
        notice.dental_premium = renewal_policy.pre_amt_tot
      rescue
        notice.dental_premium = 0
      end
      # if @type == 'qhp'
      #   notice.dental_aptc = dental.applied_aptc
      #   notice.dental_responsible_amt = dental.tot_res_amt
      # end
      notice
    end

    def append_taxhousehold(subscriber, enrollees, notice)
      ([subscriber] + enrollees).each do |enrollee|
        notice.tax_household << build_enrollee(enrollee, subscriber)
      end
      notice
    end

    private

    def build_enrollee(enrollee, subscriber)
      enrollee = PdfTemplates::RenewalEnrollee.new({
        name_first: enrollee.name_first,
        name_last: enrollee.name_last,
        name_middle: enrollee.name_middle,
        name_sfx: enrollee.name_sfx,
        residency: residency(enrollee, subscriber),
        citizenship_status: enrollee.citizenship,
        incarcerated: enrollee.incarcerated?
      })    
    end

    def residency(person, subscriber = nil)
      if person.home_address.blank?
        person = person || subscriber
      end
      if person.home_address.blank? && person.mailing_address.blank?
        return
      end
      (person.home_address || person.mailing_address).state.upcase
    end
  end
end