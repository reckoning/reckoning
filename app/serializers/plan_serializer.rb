class PlanSerializer < ActiveModel::Serializer
  attributes :uuid, :code, :name, :description, :price, :quantity, :interval, :featured

  def description
    I18n.t("plans.name.#{object.code}", price: object.price)
  end
end
