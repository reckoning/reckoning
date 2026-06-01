# frozen_string_literal: true

require "active_support/concern"

module PdfOptions
  extend ActiveSupport::Concern

  included do
    def inline_pdf_options
      {
        layout: "layouts/pdf",
        locals: {resource: self}
      }
    end

    def grover_options
      {
        format: "A4",
        margin: {
          top: "30mm",
          bottom: "38mm",
          left: "18mm",
          right: "18mm"
        },
        display_header_footer: true,
        header_template: render_pdf_partial("shared/pdf_header"),
        footer_template: render_pdf_partial("shared/pdf_footer"),
        print_background: true
      }
    end

    private def render_pdf_partial(template)
      ApplicationController.new.render_to_string(template, layout: false, locals: {resource: self})
    end
  end
end
