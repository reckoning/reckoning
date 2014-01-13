class Address < ActiveRecord::Base
  before_save :set_names, :set_contact

  belongs_to :resource, polymorphic: true

  def set_names
    if self.name.present?
      self.firstname = self.name[/^(\S+)/,1]
      self.lastname = self.name[/(\S+)$/,1]
    end
  end

  def set_contact
    full_contact = []
    full_contact << self.email.to_s unless self.email.blank?
    full_contact << self.telefon.to_s unless self.telefon.blank?
    full_contact << self.fax.to_s unless self.fax.blank?
    self.contact = full_contact.join(" | ")
  end

  def address_as_one_line
    address.gsub("\r\n", ", ").gsub("\n", ", ").gsub("\r", ", ")
  end
end
