module ActiveRecord
  class Base
    alias_method :uuid, :id
  end
end
