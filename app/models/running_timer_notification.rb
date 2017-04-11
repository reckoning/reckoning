# encoding: utf-8
# frozen_string_literal: true
class RunningTimerNotification
  include Notification

  def initialize
    self.text = I18n.t("notifications.timer.running")
    self.notification_type = "warning"
  end
end
