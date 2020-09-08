# frozen_string_literal: true

module Commands
  class Get
    def initialize(data_store, expires, args)
      @data_store = data_store
      @expires = expires
      @args = args
    end

    def call
      unless args.any?
        return "(error) ERR wrong number of arguments for 'SET' command"
      end

      key = args.first
      validating_data(key)
      @data_store.fetch(key, '(nil)')
    end

    private

    attr_reader :args, :data_store, :expires

    def validating_data(key)
      expiring_time = expires[key]
      return if expiring_time.nil? || expiring_time > Time.now.to_f * 1000

      @data_store.delete(key)
      @expires.delete(key)
    end
  end
end
