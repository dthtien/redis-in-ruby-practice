# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../src/commands/set'

describe Commands::Set do
  let(:data_store) { {} }
  let(:expires) { {} }
  let(:command) do
    described_class.new(data_store, expires, args)
  end

  describe '#call' do
    context 'without presence' do
      let(:args) { %w[key value] }
      it 'updates data_store correctly' do
        command.call
        expect(data_store['key']).to eq 'value'
      end
    end

    context 'with presence' do
      context 'presence is EX' do
        context 'when expired time present' do
          let(:args) { %w[key value EX 10] }

          before do
            command.call
          end

          it 'updates data_store correctly' do
            expect(data_store['key']).to eq 'value'
          end

          it 'updates expires correctly' do
            expect(expires['key']).to eq (Time.now.to_f * 1000).to_i + 10
          end
        end

        context 'when expired time not found' do
          let(:args) { %w[key value EX] }
          it 'raises error' do
            expect { command.call }.to raise_error Commands::Set::ValidateError
          end
        end
      end
    end
  end
end
