module Notices
  class RenewalNotice < Notice

    def initialize(args = {})
      super
      @template = "notices/renewal_1b_atena.html.erb"
      @atena_notice = args[:atena] || false
    end

    def render_notice
      generate_pdf_notice
      attach_metal_plans if @atena_notice
      attach_blank_page
      attach_voter_registration
      generate_envelope
      prepend_envelope
      @notice = nil
      # save_html
    end
  end
end
