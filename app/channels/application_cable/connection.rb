# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      logger.add_tags 'ActionCable', current_user.name
    end

    protected def find_verified_user
      user_data = JSON.parse(cookies.signed[:cable])
      verified_user = User.find_by(id: user_data['id'])
      if verified_user && Time.zone.parse(user_data['expires_at']) > Time.zone.now
        verified_user
      else
        reject_unauthorized_connection
      end
    end
  end
end
