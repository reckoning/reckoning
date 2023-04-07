# frozen_string_literal: true

module PositionHelper
  def positions_for_select
    positions = Position.all
    return [] if positions.blank?

    positions.map { |position| [position.description, position.description] }
  end

  def timer_position_fields(form)
    new_object = form.object.positions.klass.new
    id = new_object.object_id
    fields = form.fields_for(:positions, new_object, child_index: id) do |builder|
      render("#{form.object.class.name.downcase.pluralize}/timer_position_fields", fields: builder)
    end
    {id: id, fields: fields.tr("\n", "")}
  end

  def position_fields(form)
    new_object = form.object.positions.klass.new
    id = new_object.object_id
    fields = form.fields_for(:positions, new_object, child_index: id) do |builder|
      render("#{form.object.class.name.downcase.pluralize}/position_fields", fields: builder)
    end
    {id: id, fields: fields.tr("\n", "")}
  end
end
