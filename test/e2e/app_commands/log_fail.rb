# Called by Playwright when a spec fails. Slices the last bit of the
# Rails log since the most recent APPCLEANED marker (set in clean.rb)
# and dumps it next to the test report, alongside a JSON snapshot of
# the AR records visible at the moment of failure. Pattern lifted
# from cypress-on-rails' README — useful when a UI flake turns out
# to be a server-side error.
filename = command_options.fetch("runnable_full_title", "no title").gsub(/[^[:print:]]/, "")

system "tail -n 10000 -r log/#{Rails.env}.log | sed \"/APPCLEANED/ q\" | sed 'x;1!H;$!d;x' > 'log/#{filename}.log'"

json_result = {"error" => command_options.fetch("error_message", "no error message")}

if defined?(ActiveRecord::Base)
  json_result["records"] =
    ActiveRecord::Base.descendants.each_with_object({}) do |record_class, records|
      records[record_class.to_s] = record_class.limit(100).map(&:attributes)
    rescue
      # Skip models that can't be enumerated (abstract base classes, etc.)
    end
end

File.write(Rails.root.join("log/#{filename}.json"), JSON.pretty_generate(json_result))
