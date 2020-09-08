# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../src/commands/pttl'

describe Commands::Pttl do
  let(:command) do
    described_class.new(data_store, expires, args)
  end

  context 'expires data found' do
    let(:expected_number) { 3600 * 24 * 1000 }
    let(:time) { Time.now.to_f * 1000 + expected_number }
    let(:data_store) { { 'key' => 'value' } }
    let(:expires) { { 'key' => time } }
    let(:args) { %w[key] }

    it 'returns correct number' do
      expect(command.call).to be_within(0.5).of expected_number
    end
  end

  context 'expires is not found' do
    let(:data_store) { { 'key' => 'value' } }
    let(:expires) { {} }
    let(:args) { %w[key] }

    it 'returns correct number' do
      expect(command.call).to eq(-1)
    end
  end

  context 'data is not found' do
    let(:data_store) { {} }
    let(:expires) { {} }
    let(:args) { %w[key] }

    it 'returns correct number' do
      expect(command.call).to eq(-2)
    end
  end

  context 'without any options' do
    let(:data_store) { { 'key' => 'value' } }
    let(:expires) { { 'key' => (Time.now - 3600 * 24).to_f * 1000 } }
    let(:args) {[]}
    it 'returns correct error message' do
      expect(command.call).to eq "(error) ERR wrong number of arguments for 'SET' command"
    end
  end

end
