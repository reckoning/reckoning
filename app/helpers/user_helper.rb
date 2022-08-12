# frozen_string_literal: true

module UserHelper
  def last_user_logged_in(user)
    result = []
    if user.current_sign_in_at.blank?
      result << I18n.t(:'user.current_sign_in_at.empty')
    else
      result << time_ago_in_words(user.current_sign_in_at)
      result << "(#{l(user.current_sign_in_at, format: :long)})"
    end
    result.join(' ')
  end
end
