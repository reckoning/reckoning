class EmailValidator < ActiveModel::Validator
  def validate record
    unless record.email =~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
      record.errors[:email] << I18n.t(:"activerecord.errors.models.test_mail.attributes.email.invalid")
    end
  end
end
