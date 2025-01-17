module Prompts

  class FunctionParameter < Struct.new(:name, :required, :type, :description)
    def to_hash
      {
        name: name,
        required: required,
        type: type,
        description: description
      }
    end
  end

  class Function
    @@names = [] # class variable to store names

    class << self
      extend T::Sig

      sig { params(name: T.any(String, Symbol)).void }
      def name(name)
        sym_name = name.to_sym
        validate_name(sym_name)
        raise NameAlreadyTakenError, "Name already taken" if @@names.include?(sym_name)
        @@names << sym_name
        @internal_name = sym_name
      end

      sig { returns(Symbol) }
      def internal_name
        @internal_name ||= snake_case(self.to_s.split('::').last).to_sym
      end

      sig { params(description: String).returns(String) }
      def description(description = nil)
        @description = description if description
        return @description
      end

      def parameters
        @parameters ||= []
      end

      def parameter(name_or_object, **kwargs)
        case name_or_object
        when Symbol
          obj = FunctionParameter.new(name_or_object, kwargs[:required], kwargs[:type], kwargs[:description])

        when FunctionParameter
          obj = name_or_object
        else
          raise InvalidParameterError, "Invalid parameter, must be a hash or a FunctionParameter object, got #{name_or_object.class}"
        end
        parameters << obj
      end


      private

      sig { params(str: String).returns(String) }
      def snake_case(str)
        str.gsub(/::/, '/')
           .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
           .gsub(/([a-z\d])([A-Z])/, '\1_\2')
           .tr("-", "_")
           .downcase
      end

      sig { params(name: Symbol).void }
      def validate_name(name)
        valid = /\A[a-zA-Z_][a-zA-Z0-9_]*\z/ =~ name.to_s
        raise InvalidNameFormatError, "Invalid name format" unless valid
      end
    end
  end

  class NameAlreadyTakenError < StandardError; end

  class InvalidNameFormatError < StandardError; end

  class InvalidParameterError < StandardError; end
end
