# frozen_string_literal: true

module DynamicFieldsForHelper
  def link_to_add_fields(form, association, options = {}, &block)
    partial = options[:partial] || nil
    name = options[:name] || nil
    css_classes = options[:class] || nil
    target = options[:target] || nil
    new_object = form.object.send(association).klass.new
    id = new_object.object_id

    fields = form.fields_for(association, new_object, child_index: id) do |builder|
      if partial
        render("#{form.object.class.name.underscore.pluralize}/#{partial}", fields: builder)
      else
        render("#{form.object.class.name.underscore.pluralize}/#{association.to_s.singularize}_fields", fields: builder)
      end
    end

    css_classes = css_classes(DynamicFieldsForRails.add_css_classes, css_classes)

    if block_given?
      link_to('#', class: css_classes, data: { id: id, fields: fields.delete("\n"), target: target }, &block)
    else
      link_to(name, '#', class: css_classes, data: { id: id, fields: fields.delete("\n"), target: target })
    end
  end

  def link_to_delete_fields(fields, options = {}, &block)
    name = options[:name] || nil
    css_classes = options[:class] || nil

    link = []
    link << fields.hidden_field(:_destroy) unless fields.object.new_record?
    css_classes = css_classes(DynamicFieldsForRails.delete_css_classes, css_classes)

    link << if block_given?
              link_to('#', class: css_classes, title: name, &block)
            else
              link_to(name, '#', class: css_classes)
            end

    # rubocop:disable Rails/OutputSafety
    link.join('').html_safe
    # rubocop:enable Rails/OutputSafety
  end

  protected def css_classes(default, css_class)
    style_class = []
    style_class << default if default.present?
    style_class << css_class if css_class.present?
    style_class.join(' ')
  end
end
