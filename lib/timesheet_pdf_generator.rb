require "pdf_generator"

class TimesheetPdfGenerator < PdfGenerator
  def generate_html_template
    render(
      template: "#{resource.class.name.underscore.pluralize}/timesheet_pdf",
      layout: 'pdf',
      locals: {
        resource: resource
      }
    )
  end
end
