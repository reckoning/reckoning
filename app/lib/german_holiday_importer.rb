# frozen_string_literal: true

class GermanHolidayImporter
  attr_accessor :year

  def run(year:)
    @year = year

    fetch_holidays(year: year).map do |state, holidays|
      holidays.map do |name, data|
        GermanHoliday.find_or_create_by!(
          date: data["datum"],
          federal_state: state,
          name: name
        )
      end
    end
  end

  private def fetch_holidays(year:)
    response = Typhoeus.get("https://feiertage-api.de/api/?jahr=#{year}")

    return [] unless response.success?

    begin
      JSON.parse(response.body)
    rescue JSON::ParserError
      []
    end
  end
end
