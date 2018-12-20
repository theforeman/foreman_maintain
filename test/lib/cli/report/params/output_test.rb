require 'test_helper'

module ForemanMaintain
  describe Cli::Report::Params::Output do
    subject do
      Cli::Report::Params::Output
    end

    describe '.validate!' do
      it 'json is a valid format' do
        assert_nil subject.new('Json').validate!
      end

      it 'yaml is a valid format' do
        assert_nil subject.new('YAML').validate!
      end

      it 'xml is not a valid format' do
        assert_raises ArgumentError do
          subject.new('XML').validate!
        end
      end

      it 'nil is not a valid format' do
        assert_raises ArgumentError do
          subject.new(nil).validate!
        end
      end
    end

    it 'to_params returns output string value' do
      output = subject.new('JSON')
      assert_equal 'json', output.to_params
    end
  end
end
