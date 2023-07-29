# frozen_string_literal: true
# typed: true

module Prompts
  class PromptBuilder
    extend T::Sig

    attr_accessor :parameters

    def initialize
      super
      @parameters = {}
    end

    sig { returns(T::Array[Hash]) }
    def system_messages
      self.class.messages.select { |m| m.is_a?(Prompts::SystemMessage) }
    end

    sig { returns(T::Array[Hash]) }
    def user_messages
      self.class.messages.select { |m| m.is_a?(Prompts::UserMessage) }
    end

    sig { returns(T::Array[Hash]) }
    def agent_messages
      self.class.messages.select { |m| m.is_a?(Prompts::AgentMessage) }
    end

    sig { params(input_parameters: T::Hash[Symbol, String]).returns(T::Array[Hash]) }
    def missing_parameters(input_parameters = {})
      input_parameters = input_parameters.merge(parameters)
      self.class.parameters.select { |p| input_parameters[p[:label]].nil? }
    end

    sig { params(user_message: String, input_parameters: T::Hash[Symbol, String]).void }
    def invoke(user_message = "", input_parameters = {})
      raise MissingParameterValueError unless missing_parameters(input_parameters).empty?
    end

    private def setter(param_name, value, sup)
      param = self.class.parameters.find { |p| p[:label] == param_name }
      if param.nil?
        sup.call
      else
        @parameters[param_name] = value
      end
    end

    private def getter(param_name, sup)
      param = self.class.parameters.find { |p| p[:label] == param_name }
      if param.nil?
        sup.call
      else
        @parameters[param_name]
      end
    end

    def method_missing(method, *args, &block)
      if method[-1] == '='
        super unless args.length == 1
        setter(method[0..-2].to_sym, args.first, proc { super })
      else
        super if args.any?
        param_name = method
        getter(param_name.to_sym, proc { super })
      end
    end

    def respond_to_missing?(method, include_all = false)
      if method[-1] == '='
        param_name = method[0..-2].to_sym
        self.class.parameters.any? { |param| param[:label] == param_name } || super
      else
        param_name = method
        self.class.parameters.any? { |param| param[:label] == param_name } || super
      end
    end

    class << self
      extend T::Sig

      def messages
        @messages ||= []
      end

      sig { params(message: String).void }
      def system(message)
        add_message(:system, message)
      end

      sig { params(message: String).void }
      def user(message)
        add_message(:user, message)
      end

      sig { params(message: String).void }
      def agent(message)
        add_message(:agent, message)
      end

      sig { params(role: Symbol, message: String).void }
      def add_message(role, message)
        case role
        when :user
          klass = Prompts::UserMessage
        when :system
          klass = Prompts::SystemMessage
        when :agent
          klass = Prompts::AgentMessage
        else
          raise StandardError, 'Invalid role'
        end
        messages.push klass.new(message)

        parsed_message = Parser.new(message)
        parsed_message.parameter_names.select { |param_name| !parameters.any? { |param| param[:label] == param_name } }.each do |param_name|
          parameter(param_name)
        end

      end

      sig { params(label: Symbol, value: String, block: T.proc.void).void }
      def with_parameter(label, value, &block)
        # parameters << { name: name, default: default }
        temp_messages = @messages # Store existing messages
        @messages = [] # Reset @messages for capturing the ones inside the block
        self.instance_eval(&block)
        parameter_messages = @messages # These are the messages inside the block
        @messages = temp_messages # Restore existing messages
        parameter_messages.each do |message|
          message.parameter_requirements << { label: label, value: value }
          @messages << message
        end
      end

      sig { params(name: Symbol, type: T.untyped, description: String).void }
      def parameter(name, type = :untyped, description = "")
        @parameters << { label: name, type: type, description: description }
        define_method("#{name}=") do |value|
          @parameters[name] = value
        end
      end

      def parameters
        @parameters ||= []
      end

      sig { params(value: T.untyped).returns(Symbol) }
      def parse_parameter_value(value) end

    end

  end
end