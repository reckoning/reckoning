module HstoreAccessor
  extend ActiveSupport::Concern

  module ClassMethods

    def hstore_accessor(hstore, *fields)
      fields.each do |field|
        define_hstore_reader hstore, field.to_s
        define_hstore_writer hstore, field.to_s
      end
    end

    private

    def define_hstore_reader(hstore, field)
      define_method field do
        send(hstore) && send(hstore)[field]
      end
    end

    def define_hstore_writer(hstore, field)
      define_method :"#{field}=" do |val|
        val = (send(hstore) || {}).merge(field => val)
        send(:"#{hstore}=", val)
      end
    end
  end
end