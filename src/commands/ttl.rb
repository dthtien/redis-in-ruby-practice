# frozen_string_literal: true

require_relative './pttl'

module Commands
  class Ttl
    def initialize(data_store, expires, args)
      @data_store = data_store
      @expires = expires
      @args = args
    end

    def call
      unless args.any?
        return "(error) ERR wrong number of arguments for 'SET' command"
      end

      pttl = Pttl.new(data_store, expires, args).call
      return pttl if pttl.negative?

      pttl / 1000
    end

    private

    attr_reader :data_store, :expires, :args
  end
end
