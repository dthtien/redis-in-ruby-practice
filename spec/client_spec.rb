# frozen_string_literal: true

require_relative 'spec_helper'
require_relative 'helpers'
require_relative '../src/client.rb'

# Todo: add missing test :()
describe 'Client' do
  include Helpers

  let(:service) { Client.new }

  describe '#get' do
    xit 'handles unexpected number ber of arguments' do
      assert_command_results [
        ['GET', '(error) ERR wrong number of arguments for \'GET\' command']
      ]
    end
  end
end
