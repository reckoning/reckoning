module NavHelper

  def get_active_nav nav = 'home'
    if nav == @active_nav
      return "active"
    end
  end

  def back_path fallback
    if request.referer.blank?
      fallback
    else
      :back
    end
  end
end
