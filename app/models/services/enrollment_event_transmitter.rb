# Put an Enrollment Event CV onto the bus after transforming
module Services
  class EnrollmentEventTransmitter
    include Handlers::EnrollmentEventXmlHelper

    def call(amqp_connection, action_xml)
      enrollment_event_cv = enrollment_event_cv_for(action_xml)
      if is_publishable?(enrollment_event_cv)
        begin
          edi_builder = EdiCodec::X12::BenefitEnrollment.new(action_xml)
          x12_xml = edi_builder.call.to_xml
          publish_to_bus(amqp_connection, enrollment_event_cv, x12_xml)
        rescue Exception => e
          raise BusinessProcesses::TransformationError.new(action_xml, e.message)
        end
      end
    end

    def publish_to_bus(amqp_connection, enrollment_event_cv, x12_payload)
      ::Amqp::ConfirmedPublisher.with_confirmed_channel(amqp_connection) do |chan|
        ex = chan.default_exchange
        ex.publish(x12_payload, :routing_key => routing_key(enrollment_event_cv), :headers => {
          "market" => determine_market(enrollment_event_cv),
          "file_name" => determine_file_name(enrollment_event_cv)
        })
      end
    end

    def find_carrier_abbreviation(enrollment_event_cv)
      policy_cv = extract_policy(enrollment_event_cv)
      hios_id = extract_hios_id(policy_cv)
      active_year = extract_active_year(policy_cv)
      found_plan = Plan.where(:hios_plan_id => hios_id, :year => active_year.to_i).first
      found_plan.carrier.abbrev.upcase
    end

    def determine_file_name(enrollment_event_cv)
      market_identifier = shop_market?(enrollment_event_cv) ? "S" : "I"
      carrier_identifier = find_carrier_abbreviation(enrollment_event_cv)
      category_identifier = is_initial?(enrollment_event_cv) ? "_C_E_" : "_C_M_"
      "834_" + transaction_id(enrollment_event_cv) + "_" + carrier_identifier + category_identifier + market_identifier + "_1.xml"
    end

    protected

    def is_publishable?(enrollment_event_cv)
      Maybe.new(enrollment_event_cv).event.body.publishable?.value
    end

    def is_initial?(enrollment_event_cv)
      event_name = Maybe.new(enrollment_event_cv).event.body.enrollment.enrollment_type.strip.split("#").last.downcase.value
      (event_name == "initial")
    end

    def routing_key(enrollment_event_cv)
      is_initial?(enrollment_event_cv) ? "hbx.enrollment_messages" : "hbx.maintenance_messages"
    end

    def transaction_id(enrollment_event_cv)
      Maybe.new(enrollment_event_cv).event.body.transaction_id.strip.value
    end

    def shop_market?(enrollment_event_cv)
      determine_market(enrollment_event_cv) == "shop"
    end
  end
end
