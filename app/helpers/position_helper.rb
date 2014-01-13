module PositionHelper
  def positions_for_select
  	positions = Position.all
  	if positions.present?
  		return positions.map{|position| [position.description, position.description]}
  	else
  		return []
  	end
  end
end