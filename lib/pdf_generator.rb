class PdfGenerator < AbstractController::Base
  include AbstractController::Logger
  include AbstractController::Rendering
  include AbstractController::Layouts
  include AbstractController::Helpers
  include AbstractController::Translation
  include AbstractController::AssetPaths
  include ActionController::RequestForgeryProtection
  include ActionView::Helpers::AssetTagHelper

  attr_accessor :resource

  self.view_paths = "app/views"
  def session; {}; end

  def initialize resource
    @resource = resource
  end

  def generate
    html_template = generate_html_template
    call_weasyprint html_template
  end

  def generate_html_template
    content = render({
      template: "#{resource.class.name.underscore.pluralize}/pdf",
      layout: 'pdf',
      locals: {
        resource: resource
      }
    })
  end

  def call_weasyprint html
    file = Tempfile.new('reckoning-pdf')
    file.open
    file.write(html)
    file.close
    system "#{Settings.app.py_env}weasyprint #{file.path} #{resource.pdf_path}" # generate pdf
    system "#{Settings.app.py_env}weasyprint #{file.path} #{resource.png_path} -f png" # generate png for preview
    file.unlink
  end
end
