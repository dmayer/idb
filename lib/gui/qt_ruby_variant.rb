module Idb
  class Qt::RubyVariant < Qt::Variant
      def initialize(value)
          super()
          @value = value
      end

      attr_accessor :value
  end

  class Object
      def to_variant
          Qt::RubyVariant.new self
      end
  end
end
