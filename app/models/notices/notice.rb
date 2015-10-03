require 'prawn'

module Notices
  class Notice
    attr_accessor :from, :to, :subject, :template, :notice, :mkt_kind, :file_name, :notice_path

    def initialize(args = {})
      @template = args[:template]
      @notice = args[:notice]
      @email_notice = args[:email_notice] || true
      @pdf_notice = args[:pdf_notice] || true
      @notice_path = Rails.root.join('pdfs', 'notice.pdf')
      @blank_sheet_path = Rails.root.join('lib/pdf_pages', 'blank.pdf')
      @envelope_path = Rails.root.join('pdfs', 'envelope.pdf')
      @voter_registration = Rails.root.join('lib/pdf_pages', 'voter_application.pdf')
      @metal_plans_path = Rails.root.join('pdfs', 'metal_plans.pdf')
    end

    def html(template=nil)
      ApplicationController.new.render_to_string({ 
        :template => template || @template,
        :layout => 'pdf_notice_layout',
        :locals => { notice: @notice }
        })
    end

    def save_html
      File.open(Rails.root.join('pdfs','notice.html'), 'wb') do |file|
        file << self.html
      end
    end

    def pdf
      WickedPdf.new.pdf_from_string(
        self.html,
        margin:  {  
          top: 15,
          bottom: 30,
          left: 22,
          right: 22 
        },
        disable_smart_shrinking: true,
        dpi: 96,
        page_size: 'Letter',
        formats: :html,
        encoding: 'utf8',
        footer: { 
          content: ApplicationController.new.render_to_string({ 
            template: "notices/ivl/footer.html.erb", 
            layout: false 
          })
        }
      )
    end

    def generate_pdf_notice
      File.open(@notice_path, 'wb') do |file|
        file << self.pdf
      end
    end

    def join_pdfs(pdfs)
      Prawn::Document.generate(@notice_path, {:page_size => 'LETTER', :skip_page_creation => true}) do |pdf|
        pdfs.each do |pdf_file|
          if File.exists?(pdf_file)
            pdf_temp_nb_pages = Prawn::Document.new(:template => pdf_file).page_count

            (1..pdf_temp_nb_pages).each do |i|
              pdf.start_new_page(:template => pdf_file, :template_page => i)
            end
          end
        end
      end
    end

    def attach_blank_page
      page_count = Prawn::Document.new(:template => @notice_path).page_count
      if (page_count % 2) == 1
        join_pdfs [@notice_path, @blank_sheet_path]
      end
    end

    def attach_voter_registration
      join_pdfs [@notice_path, @voter_registration]
    end

    def attach_metal_plans
      generate_metal_plans
      join_pdfs [@notice_path, @metal_plans_path]
    end

    def generate_metal_plans
      File.open(@metal_plans_path, 'wb') do |file|
        file << WickedPdf.new.pdf_from_string(
          self.html("notices/metal_plans.html.erb"),
          margin:  {  
            top: 15,
            bottom: 30,
            left: 22,
            right: 22 
          },
          disable_smart_shrinking: true,
          dpi: 96,
          page_size: 'Letter',
          formats: :html,
          encoding: 'utf8'
        )
      end
    end

    def generate_envelope
      envelope = Notices::Envelope.new 
      envelope.fill_envelope(@notice)
      envelope.render_file(@envelope_path)
    end

    def prepend_envelope
      join_pdfs [@envelope_path, @notice_path]
    end
  end

  class Envelope < Generators::Reports::PdfReport

    def initialize
      template = Rails.root.join('lib/pdf_pages', 'ivl_envelope.pdf')

      super({:template => template, :margin => [30, 55]})
      font_size 11
      
      @margin = [30, 70]
    end

    def fill_envelope(notice)
      x_pos = mm2pt(21.83) - @margin[0]
      y_pos = 790.86 - mm2pt(57.15) - 65

      bounding_box([x_pos, y_pos], :width => 300) do
        fill_recipient_contact(notice)
      end

      x_pos = mm2pt(6.15)
      y_pos = 57

      bounding_box([x_pos, y_pos], :width => 300) do
        text "MPI_IVLR1"
      end
    end

    def fill_recipient_contact(notice)
      text notice.primary_name
      text notice.primary_address.street_1
      text notice.primary_address.street_2 unless notice.primary_address.street_2.blank?
      text "#{notice.primary_address.city}, #{notice.primary_address.state} #{notice.primary_address.zip}"      
    end
  end
end

