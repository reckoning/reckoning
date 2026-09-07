# frozen_string_literal: true

require "test_helper"

# The PDFs are rendered by Chrome through Grover, and Chrome renders a
# document's running header and footer as separate documents: they load no
# external stylesheet and no webfont, and an embedded `@font-face` does not
# reach them either. Grover hands the page over by intercepting the first
# request (`grover/js/processor.cjs`), so a linked font would depend on the
# network at render time as well.
#
# Both families are therefore installed in the image (`vendor/fonts`, copied in
# the Dockerfile) and named as plain system fonts. This test guards the naming;
# whether the files are in the image is the Dockerfile's business.
class PdfFontsTest < ActionDispatch::IntegrationTest
  let(:layout) { Rails.root.join("app/views/layouts/pdf.html.erb").read }
  let(:header) { Rails.root.join("app/views/shared/pdf_header.html.erb").read }
  let(:footer) { Rails.root.join("app/views/shared/pdf_footer.html.erb").read }
  let(:stylesheet) { Rails.application.assets["pdf.css"].to_s }

  it "asks for no font from the network" do
    assert_not_includes layout, "fonts.googleapis.com",
      "a linked font never reaches the running header, and ties the render to the network"
  end

  # Until this was fixed the body named `Helvetica Neue, Helvetica, Arial` —
  # a wish list that resolved to Helvetica Neue on a developer's Mac and to
  # Liberation Sans in the container, so no two hosts agreed.
  it "sets the body in the installed text face" do
    assert_includes stylesheet, "Noto Sans"
    assert_not_includes stylesheet, "Helvetica"
  end

  it "sets the headlines in the brand face" do
    assert_match(/h1,\s*h2,\s*h3\s*\{[^}]*Orbitron/m, stylesheet)
  end

  # These two are their own documents, so they carry their own font stack.
  it "names both faces in the header and footer templates" do
    assert_includes header, "Orbitron"
    assert_includes footer, "Noto Sans"
    assert_not_includes footer, "Helvetica"
  end
end
