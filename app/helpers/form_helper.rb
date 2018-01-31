# frozen_string_literal: true

module FormHelper
  def form_error?(obj, method)
    obj.errors[method].empty? ? '' : 'has-error has-feedback'
  end

  def form_errors(obj, method, css_classes = "")
    errors = obj.errors[method]
    return if errors.empty?
    content_tag(:span, "", title: errors.join(' '),
                           class: "fa fa-warning form-control-feedback #{css_classes}",
                           data: { toggle: "tooltip", placement: "left" })
  end
end
