# frozen_string_literal: true

class TimerMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  default from: Rails.application.secrets[:mailer_default_from].to_s

  attr_accessor :timer

  def notify(timer)
    self.timer = timer
    send_mail timer.user.email
  end

  private def send_mail(to)
    @timer = timer
    mail(
      from: from,
      to: to,
      subject: I18n.t(:'mailer.timer.notify.subject'),
      template_name: 'notify'
    )
  end

  private def from
    @from ||= Rails.application.secrets[:mailer_default_from].to_s
  end
end
