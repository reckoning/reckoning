# frozen_string_literal: true

Grover.configure do |config|
  config.options = {
    format: "A4",
    cache: false,
    wait_until: "networkidle0",
    launch_args: ["--no-sandbox", "--disable-dev-shm-usage", "--disable-gpu"]
  }
end
