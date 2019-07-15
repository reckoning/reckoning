# frozen_string_literal: true

module NavHelper
  def active_nav?(navs = 'home')
    navs = [navs] unless navs.is_a?(Array)
    # rubocop:disable Rails/HelperInstanceVariable
    return unless navs.any? { |nav| nav == @active_nav }

    # rubocop:enable Rails/HelperInstanceVariable

    'active'
  end

  def hide_nav?(nav = 'home')
    # rubocop:disable Rails/HelperInstanceVariable
    return 'hide' if nav == @active_nav
    # rubocop:enable Rails/HelperInstanceVariable
  end

  def back_path(fallback)
    if request.referer.blank?
      fallback
    else
      :back
    end
  end
end
