class PdfGenerator < AbstractController::Base
  include AbstractController::Rendering
  include ActionView::Layouts
  include AbstractController::Helpers

  attr_accessor :resource, :tempfile, :pdf_path

  self.view_paths = Rails.root.join("app","views")

  def initialize resource, options
    @resource = resource
    @pdf_path = options.fetch(:pdf_path)
    @tempfile = options.fetch(:tempfile)
  end

  def generate
    html_template = generate_html_template
    call_pdf_lib html_template
  end

  def generate_html_template
    raise NotImplementedError.new
  end

  def call_pdf_lib html
    file = Tempfile.new(tempfile)
    file.open
    file.write(html)
    file.close
    system "weasyprint #{file.path} #{@pdf_path}"
    file.unlink
  end
end
