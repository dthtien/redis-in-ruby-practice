# frozen_string_literal: true

require_relative 'spec_helper'
require_relative 'helpers'
require_relative '../src/server.rb'

# TODO: implement better test
describe 'Server' do
  include Helpers

  let(:service) { Server.new }

  describe '#execute' do
    let(:executer) { service.execute }

    it 'listens on port Server::DEFAULT_PORT' do
      lsof_result = ''
      with_server do
        lsof_result = `lsof -nP -i4TCP:2020 | grep LISTEN`
        expect(lsof_result).to match 'ruby'
      end
    end
  end
end
