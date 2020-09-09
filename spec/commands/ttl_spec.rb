# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../src/commands/ttl'

describe Commands::Ttl do
  let(:command) do
    described_class.new(data_store, expires, args)
  end

  context 'call success' do
    let(:expected_number) { 3600 * 24 }
    let(:time) { Time.now.to_f * 1000 + expected_number * 1000 }
    let(:data_store) { { 'key' => 'value' } }
    let(:expires) { { 'key' => time } }
    let(:args) { %w[key] }

    before do
      allow(Commands::Pttl)
        .to receive(:new).and_return(double(call: expected_number * 1000))
    end

    it 'returns correct number' do
      expect(command.call).to be_within(0.5).of(expected_number)
    end
  end

  context 'without any options' do
    let(:data_store) { { 'key' => 'value' } }
    let(:expires) { { 'key' => (Time.now - 3600 * 24).to_f * 1000 } }
    let(:args) { [] }

    it 'returns correct error message' do
      expect(command.call).to eq "(error) ERR wrong number of arguments for 'SET' command"
    end
  end
end
