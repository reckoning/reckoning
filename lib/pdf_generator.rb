class PdfGenerator < AbstractController::Base
  include AbstractController::Logger
  include AbstractController::Rendering
  include AbstractController::Layouts
  include AbstractController::Helpers
  include AbstractController::Translation
  include AbstractController::AssetPaths
  include ActionController::RequestForgeryProtection
  include ActionView::Helpers::AssetTagHelper

  attr_accessor :resource, :tempfile, :pdf_path, :png_path

  self.view_paths = "app/views"
  def session; {}; end

  def initialize resource, options
    @resource = resource
    @pdf_path = options.fetch(:pdf_path)
    @png_path = options.fetch(:png_path)
    @tempfile = options.fetch(:tempfile)
  end

  def generate
    html_template = generate_html_template
    call_weasyprint html_template
  end

  def generate_html_template
    raise NotImplementedError.new
  end

  def call_weasyprint html
    file = Tempfile.new(tempfile)
    file.open
    file.write(html)
    file.close
    system "weasyprint #{file.path} #{@pdf_path}" # generate pdf
    system "weasyprint #{file.path} #{@png_path} -f png" # generate png for preview
    file.unlink
  end
end
