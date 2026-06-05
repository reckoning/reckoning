# Truncates the test database between specs. The :transaction
# strategy that the Minitest suite uses doesn't work for e2e because
# the Playwright browser issues real HTTP requests that run in their
# own threads / connections.
if defined?(DatabaseCleaner)
  DatabaseCleaner.strategy = :truncation
  DatabaseCleaner.clean
else
  logger.warn "DatabaseCleaner not loaded — add `database_cleaner` to Gemfile or update test/e2e/app_commands/clean.rb"
end

Rails.logger.info "APPCLEANED" # marker for log_fail.rb's tail-until-marker
