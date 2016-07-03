# encoding: utf-8
# frozen_string_literal: true
require 'net/http'

class ContactsController < ApplicationController
  skip_authorization_check
  before_action :authenticate_user!, only: []

  def create
    if verify_captcha
      Contact.new(contact_params).save
      cookies.permanent.signed[:_reckoning_contact] = contact_params[:email]
      redirect_to "#{root_path}#contact", flash: { success: I18n.t(:"messages.contact.create.success") }
    else
      redirect_to "#{root_path}#contact", flash: { alert: I18n.t(:"messages.contact.create.failure") }
    end
  end

  private def contact_params
    params.require(:contact).permit(:email)
  end

  private def verify_captcha
    response = JSON.parse(Typhoeus.post(
      'https://www.google.com/recaptcha/api/siteverify',
      body: {
        secret: "6LfePAkTAAAAAK9myYnkYnkk5zY7tXFMSVIWa36N",
        response: params["g-recaptcha-response"]
      }
    ).body)
    response["success"]
  end
end
