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
  # Naming the face somewhere in the stylesheet is not enough: it sat on
  # `#pagination` alone, an element the main document does not even have —
  # Chrome renders the footer from its own template — so every line of every
  # invoice was still set in whatever `sans-serif` resolved to.
  it "sets the body in the installed text face" do
    assert_match(/body\s*\{[^}]*font-family:\s*"Noto Sans"/m, stylesheet)
    assert_not_includes stylesheet, "Helvetica"
  end

  # ERB escapes whatever `<%= %>` returns, and a `<style>` block decodes no
  # entities, so `&quot;Noto Sans&quot;` is not a family name — the whole
  # declaration is dropped and the document falls back to the generic
  # sans-serif. That is why every invoice stayed in Helvetica after the face
  # was installed, and why only `Orbitron`, which needs no quotes, came
  # through.
  it "inlines the stylesheet without escaping the quotes around a family" do
    html = ApplicationController.new.render_to_string(
      "invoices/pdf", invoices(:january).inline_pdf_options
    )
    style = html[/<style[^>]*>(.*?)<\/style>/m, 1]

    assert style, "the layout inlines the stylesheet in a style block"
    assert_includes style, 'font-family:"Noto Sans"'
    assert_not_includes style, "&quot;"
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

  # A name in a stylesheet only resolves if a font of that family is installed.
  # `fc-cache` reads the family out of the file rather than off the filename,
  # so a file swapped for one with a different family name inside would leave
  # every document on the fallback again — silently. The Dockerfile asserts the
  # same thing against fontconfig when the image is built.
  it "ships fonts whose own family names are the ones asked for" do
    {"NotoSans.ttf" => "Noto Sans", "Orbitron.ttf" => "Orbitron"}.each do |file, family|
      assert_equal family, font_family(Rails.root.join("vendor/fonts", file)),
        "#{file} calls itself something else, so the stylesheets would never find it"
    end
  end

  # The `name` table of a TrueType file: name ID 16 is the typographic family
  # a variable font prefers, name ID 1 the legacy one.
  private def font_family(path)
    data = path.binread
    count, = data[4, 2].unpack("n")
    records = count.times.map { |index| data[12 + (index * 16), 16].unpack("a4NNN") }
    _, _, offset, = records.find { |tag, _| tag == "name" }

    name_count, string_offset = data[offset + 2, 4].unpack("nn")
    names = name_count.times.map do |index|
      platform, _, _, name_id, length, name_offset = data[offset + 6 + (index * 12), 12].unpack("n6")
      next unless platform == 3

      [name_id, data[offset + string_offset + name_offset, length].encode("UTF-8", "UTF-16BE")]
    end.compact.to_h

    names[16] || names[1]
  end
end
