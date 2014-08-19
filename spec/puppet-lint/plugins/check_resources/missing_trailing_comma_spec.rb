require 'spec_helper'

describe 'missing_trailing_comma' do
  let(:code) {"
    file { 'foo':
      foo => bar,
      baz => qux
    }"
  }
  let(:msg) { 'line should end in comma' }

  context 'one-liners' do
    let(:code) { "
        class{'some_class':}
        include 'a_module'
      "}

    it 'should not detect any problems' do
      expect(problems).to have(0).problem
    end
  end

  context 'with fix disabled' do
    it 'should only detect a single problem' do
      expect(problems).to have(1).problem
    end

    it 'should create an error' do
      expect(problems).to contain_error(msg).on_line(4).in_column(17)
    end
  end

  context 'with fix enabled' do
    before do
      PuppetLint.configuration.fix = true
    end

    after do
      PuppetLint.configuration.fix = false
    end

    it 'should only detect a single problem' do
      expect(problems).to have(1).problem
    end

    it 'should add the trailing comma' do
      fixed_manifest = "
    file { 'foo':
      foo => bar,
      baz => qux,
    }"
      expect(manifest).to eql fixed_manifest
    end
  end
end
