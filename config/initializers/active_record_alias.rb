class ActiveRecord::Base
  alias_method :uuid, :id
end
