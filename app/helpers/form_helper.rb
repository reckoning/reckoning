module FormHelper
  def form_error?(obj, method)
    obj.errors[method].empty? ? '' : 'has-error has-feedback'
  end

  def form_errors(obj, method)
    errors = obj.errors[method]
    return if errors.empty?
    content_tag(:span, "", title: errors.join(' '),
                           class: "fa fa-warning form-control-feedback",
                           data: { toggle: "tooltip", placement: "left" })
  end
end
