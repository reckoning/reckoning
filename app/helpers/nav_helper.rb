# frozen_string_literal: true

module NavHelper
  def active_nav?(navs = "home")
    navs = [navs] unless navs.is_a?(Array)
    return unless navs.any? { |nav| nav == @active_nav }

    'active'
  end

  def hide_nav?(nav = "home")
    return "hide" if nav == @active_nav
  end

  def back_path(fallback)
    if request.referer.blank?
      fallback
    else
      :back
    end
  end
end
