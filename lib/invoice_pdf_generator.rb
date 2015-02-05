require "pdf_generator"

class InvoicePdfGenerator < PdfGenerator
  def generate_html_template
    render(
      template: "#{resource.class.name.underscore.pluralize}/pdf",
      layout: 'pdf',
      locals: {
        resource: resource
      }
    )
  end
end
