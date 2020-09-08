# frozen_string_literal: true

module Commands
  class Set
    ValidateError = Class.new StandardError
    CommandOption = Struct.new(:kind)
    CommandOptionWithValue = Struct.new(:kind, :validator)

    OPTIONS = {
      'EX' => CommandOptionWithValue.new(
        'expire',
        ->(value) { validate_integer(value) * 1000 }
      ),
      'PX' => CommandOptionWithValue.new(
        'expire',
        ->(value) { validate_integer(value) }
      ),
      'KEEPTTL' => CommandOption.new('expire'),
      'NX' => CommandOption.new('presence'),
      'XX' => CommandOption.new('presence')
    }.freeze

    def self.validate_integer(str)
      Integer(str)
    rescue ArgumentError, TypeError
      raise ValidateError, '(error) ERR value is not an integer or out of range'
    end

    def initialize(data_store, expires, args)
      @data_store = data_store
      @expires = expires
      @args = args
      @options = {}
    end

    def call
      unless @args.any?
        return "(error) ERR wrong number of arguments for 'SET' command"
      end

      key, value = @args.shift(2)
      parse_result = parse_options
      return parse_result unless parse_result.nil?

      existing_key = @data_store[key]
      return '(nil)' if @options['presence'] == 'NX' && !existing_key.nil?
      return '(nil)' if @options['presence'] == 'XX' && existing_key.nil?

      @data_store[key] = value
      process_expire(key)
      'OK'
    end

    def process_expire(key)
      expire_option = @options['expire']

      # The implied third branch is if expire_option == 'KEEPTTL',
      # in which case we don't have
      # to do anything
      if expire_option.is_a? Integer
        @expires[key] = (Time.now.to_f * 1000).to_i + expire_option
      elsif expire_option.nil?
        @expires.delete(key)
      end
    end

    def parse_options
      while @args.any?
        option = @args.shift
        option_detail = OPTIONS[option]
        return '(error) ERR syntax error' unless option_detail

        option_values = parse_option_arguments(option, option_detail)
        existing_option = @options[option_detail.kind]
        return '(error) ERR syntax error' if existing_option

        @options[option_detail.kind] = option_values
      end
    end

    def parse_option_arguments(option, option_detail)
      case option_detail
      when CommandOptionWithValue
        option_value = @args.shift
        option_detail.validator.call(option_value)
      when CommandOption
        option
      else
        raise "Unknown command option type: #{option_detail}"
      end
    end
  end
end
