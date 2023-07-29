require 'spec_helper'

class Translate < Prompts::Prompt
  system 'You are a helpful assistant that translates any text to English.'
  user 'Translate "hello" to Spanish.'
  agent 'This is not the kind of question I am expecting.'
  user 'Translate "Hola"'
  agent 'Hello'
end

class TranslateToEnglish < Prompts::Prompt
  system 'You are a helpful assistant that translates any text to English.'
  user 'Translate "hello" to Spanish.'
  agent 'This is not the kind of question I am expecting.'
  user 'Translate "Hola"'
  agent 'Hello'
end

class TranslateTo < Prompts::Prompt
  system 'You are a helpful assistant that translates any text to {{target_language}}.'
  with_parameter :target_language, "Spanish" do |language|
    user 'Translate "hello"'
    agent 'Hello'
  end
  user 'Translate "Hola"'
  agent 'Hello'
  parameter :language, :string, "The language to translate to."
end

class TranslateToEnglish < Prompts::Prompt
  system 'You are a helpful assistant that translates any text to English.'
  user 'Translate "hello" to Spanish.'
  agent 'This is not the kind of question I am expecting.'
  user 'Translate "Hola"'
  agent 'Hello'
end

class TranslateTo < Prompts::Prompt
  system 'You are a helpful assistant that translates any text to {{target_language}}.'
  with_parameter :target_language, "Spanish" do |language|
    user 'Translate "hello"'
    agent 'Hello'
  end
  user 'Translate "Hola"'
  agent 'Hello'
  parameter :language, :string, "The language to translate to."
end

describe Prompts::Prompt do
  let(:translate_prompt) { Translate.new }

  describe '.system' do
    it 'stores system prompt' do
      expect(translate_prompt.system_prompts.count).to eq(1)
    end

    context 'when parameters are present' do
      it 'stores system prompt with parameters' do
        expect(translate_to.system_prompts.count).to eq(1)
      end
    end
  end

  describe '.user' do
    it 'stores user prompts in order' do
      expect(translate_prompt.user_prompts.count).to eq(2)

    end
  end

  describe '.agent' do
    it 'stores agent prompts in order' do
      expect(translate_prompt.agent_prompts.count).to eq(2)
    end
  end

  describe '#invoke' do
    it 'responds to invoke method' do
      expect(translate_prompt).to respond_to(:invoke)
    end

    context 'when parameters are required' do
      it 'throws error when missing required parameters' do
        expect { translate_to.invoke('Translate "Hello"') }.to raise_error(MissingParameterValueError)
      end
    end

  end

  describe 'parameter setters' do
    it 'allows setting the value of parameters' do
      translate_to.target_language = 'Spanish'
      expect(translate_to.target_language).to eq('Spanish')
    end
  end

  describe '.parameter' do
    it 'stores parameter information' do
      expect(translate_to.parameters).to include(an_object_having_attributes(label: 'language', type: :string, description: "The language to translate to."))
    end
  end

  describe '#missing_parameters' do
    it 'returns parameters with missing values' do
      expect(translate_to.missing_parameters).to eq(translate_to.parameters)
    end
  end

end