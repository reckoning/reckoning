module NavHelper
  def get_active_nav(nav = 'home')
    return "active" if nav == @active_nav
  end

  def back_path(fallback)
    if request.referer.blank?
      fallback
    else
      :back
    end
  end
end
