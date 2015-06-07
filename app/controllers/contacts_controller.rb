class ContactsController < ApplicationController
  skip_authorization_check
  before_action :authenticate_user!, :only => []

  def create
    Contact.new(contact_params).save
    cookies.permanent.signed[:_reckoning_contact] = contact_params[:email]
    redirect_to "#{root_path}#contact", notice: I18n.t(:"messages.contact.create.success")
  end

  private

  def contact_params
    params.require(:contact).permit(:email)
  end
end