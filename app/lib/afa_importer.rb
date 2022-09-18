# frozen_string_literal: true

class AfaImporter
  AFA_CSV_URL = 'https://www.bundesfinanzministerium.de/Datenportal/Daten/offene-daten/steuern-zoelle/afa-tabellen/datensaetze/AfA-Tabelle_allgemein-verwendbare-Anlagengueter_alphabetisch_csv.csv?__blob=publicationFile&v=3'

  def run
    download_csv unless File.exist?(csv_file)

    unless File.exist?(csv_file)
      Rails.logger.error "AfaImporter: CSV file not found: #{csv_file}"
      return
    end

    data = CSV.read(csv_file, col_sep: ';')
      .drop(3)
      .map do |row|
        {
          name: row[0],
          years: row[1].to_i,
          key: row[2]
        }
      end

    I18n.locale = :de

    imported_ids = []

    data.each do |row|
      afa_type = AfaType.i18n.find_or_create_by!(name: row[:name], key: row[:key]) do |new_afa_type|
        new_afa_type.value = row[:years]
        new_afa_type.valid_from = Date.new(1970, 1, 1)
      end

      afa_type.update(value: row[:years]) if afa_type.value != row[:years]

      imported_ids << afa_type.id
    end
  end

  private def download_csv
    response = Typhoeus.get(AFA_CSV_URL)

    return unless response.success?

    body = response.body.force_encoding('ISO-8859-1')

    File.write(csv_file, body)
  end

  private def csv_file
    Rails.root.join('tmp/afa.csv')
  end
end
