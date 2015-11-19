module NavHelper
  def active_nav?(navs = "home")
    navs = [navs] unless navs.is_a?(Array)
    return unless navs.any? { |nav| nav == @active_nav }

    'active'
  end

  def nav_aside?
    nav_layout == "aside"
  end

  def nav_layout
    if defined?(current_user) && user_signed_in?
      current_user.layout
    else
      "top"
    end
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
