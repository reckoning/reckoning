# encoding: utf-8
# frozen_string_literal: true
class CleanupAuthTokensWorker
  include Sidekiq::Worker
  sidekiq_options queue: (ENV['CLEANUP_QUEUE'] || 'reckoning-cleanup').to_sym

  def perform
    AuthToken.system.where.not(expires: nil).find_each do |token|
      token.destroy if Time.zone.now.to_i > token.expires
    end
  end
end
