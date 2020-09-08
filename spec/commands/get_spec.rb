# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../src/commands/get'

describe Commands::Get do
  let(:command) do
    described_class.new(data_store, expires, args)
  end

  context 'data is not expired' do
    context 'data is found' do
      let(:data_store) { { 'key' => 'value' } }
      let(:expires) { {} }
      let(:args) { %w[key] }
      it 'returns correct data' do
        expect(command.call).to eq 'value'
      end
    end

    context 'data is not found' do
      let(:data_store) { {} }
      let(:expires) { {} }
      let(:args) { %w[key] }
      it 'returns correct data' do
        expect(command.call).to eq '(nil)'
      end
    end
  end

  context 'data is expired' do
    let(:data_store) { { 'key' => 'value' } }
    let(:expires) { { 'key' => (Time.now - 3600 * 24).to_f * 1000 } }
    let(:args) { %w[key] }
    it 'returns correct data' do
      expect(command.call).to eq '(nil)'
    end
  end
end
