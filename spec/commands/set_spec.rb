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
    context 'without option' do
      let(:args) { %w[key value] }
      it 'updates data_store correctly' do
        command.call
        expect(data_store['key']).to eq 'value'
      end
    end

    context 'with single option' do
      context 'option is EX' do
        context 'when expired time present' do
          let(:args) { %w[key value EX 10] }

          before do
            command.call
          end

          it 'updates data_store correctly' do
            expect(data_store['key']).to eq 'value'
          end

          it 'updates expires correctly' do
            expect(expires['key'])
              .to be_within(10).of((Time.now.to_f * 1000).to_i + 10 * 1000)
          end
        end

        context 'when expired time not found' do
          let(:args) { %w[key value EX] }
          let(:expires) { { key: Time.now.to_i } }
          it 'raises error' do
            expect { command.call }.to raise_error Commands::Set::ValidateError
          end
        end
      end

      context 'option is PX' do
        context 'when expired time present' do
          let(:args) { %w[key value PX 10] }

          before do
            command.call
          end

          it 'updates data_store correctly' do
            expect(data_store['key']).to eq 'value'
          end

          it 'updates expires correctly' do
            expect(expires['key'])
              .to be_within(10).of((Time.now.to_f * 1000).to_i + 10)
          end
        end

        context 'when expired time not found' do
          let(:args) { %w[key value PX] }
          let(:expires) { { key: Time.now.to_i } }
          it 'raises error' do
            expect { command.call }.to raise_error Commands::Set::ValidateError
          end
        end
      end

      context 'option is NX' do
        let(:args) { %w[key value NX] }
        context 'when key does not present' do
          before do
            command.call
          end

          it 'updates data_store correctly' do
            expect(data_store['key']).to eq 'value'
          end
        end

        context 'when key present' do
          let(:data_store) { { 'key' => 'ahihi' } }
          it 'return (nil)' do
            expect(command.call).to eq '(nil)'
          end
        end
      end

      context 'option is XX' do
        let(:args) { %w[key value XX] }
        context 'when key present' do
          let(:data_store) { { 'key' => 'ahihi' } }
          before do
            command.call
          end

          it 'updates data_store correctly' do
            expect(data_store['key']).to eq 'value'
          end
        end

        context 'when key present' do
          it 'return (nil)' do
            expect(command.call).to eq '(nil)'
          end
        end
      end
    end


    context 'mix options' do
      context 'XX with EX' do
        let(:args) { %w[key value XX EX 10] }
        context 'when key present' do
          let(:data_store) { { 'key' => 'ahihi' } }
          before do
            command.call
          end

          it 'updates data_store correctly' do
            expect(data_store['key']).to eq 'value'
          end

          it 'updates expires correctly' do
            expect(expires['key'])
              .to be_within(10).of((Time.now.to_f * 1000).to_i + 10 * 1000)
          end
        end

        context 'when key present' do
          it 'return (nil)' do
            expect(command.call).to eq '(nil)'
          end
        end
      end

      context 'NX with KEEPTTL' do
        let(:args) { %w[key value KEEPTTL NX] }
        let(:expires) { { 'key' => Time.now.to_i } }
        context 'option is NX' do
          context 'when key does not present' do
            before do
              command.call
            end

            it 'updates data_store correctly' do
              expect(data_store['key']).to eq 'value'
            end

            it 'updates expires correctly' do
              expect(expires['key']).to be_truthy
            end
          end

          context 'when key present' do
            let(:data_store) { { 'key' => 'ahihi' } }
            it 'return (nil)' do
              expect(command.call).to eq '(nil)'
            end
          end
        end
      end
    end

    context 'without any options' do
      let(:args) {[]}
      it 'returns correct error message' do
        expect(command.call).to eq "(error) ERR wrong number of arguments for 'SET' command"
      end
    end
  end
end
