# frozen_string_literal: true

module Commands
  class Set
    ValidateError = Class.new StandardError
    def initialize(data_store, expires, args)
      @data_store = data_store
      @expires = expires
      @args = args
    end

    def call
      key, value = @args.shift(2)
      presence = @args.shift

      case presence
      when 'EX'
        time = Float @args.shift, exception: false
        raise(ValidateError) if time.nil?

        @data_store[key] = value
        @expires[key] = (Time.now.to_f * 1000).to_i + time
      else
        @data_store[key] = value
      end
      'ok'
    end
  end
end
