# frozen_string_literal: true

class InvoicePosition < Position
  has_many :timers, foreign_key: :position_id, dependent: :nullify, inverse_of: :position

  accepts_nested_attributes_for :timers

  # Timers are picked per project, and the invoice takes its customer and its
  # rate from the project — so time from a different project would be billed
  # to the wrong customer at the wrong rate. The picker only ever offers the
  # selected project's timers; this is what holds when the request is built
  # by hand, or when the project is changed after the fact.
  validate :timers_from_the_invoiced_project

  def invoice
    invoicable
  end

  private def timers_from_the_invoiced_project
    project_id = invoicable&.project_id
    return if project_id.blank?

    foreign = timers.reject { |timer| timer.task&.project_id == project_id }
    return if foreign.empty?

    errors.add(:timers, I18n.t(:"messages.invoice.foreign_timers"))
  end
end
