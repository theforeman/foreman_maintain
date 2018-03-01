require 'test_helper'

module ForemanMaintain
  describe Cli::Report::Params::Size do
    subject do
      Cli::Report::Params::Size
    end

    describe 'is valid' do
      it "if size is greater than equal '>=1m'" do
        size = subject.new('>=1m')
        assert_nil size.validate!
      end

      it "if size is less than equal '<=500kb'" do
        size = subject.new('<=500kb')
        assert_nil size.validate!
      end

      it "if size is less than equal space in-between '<= 9b'" do
        size = subject.new('<= 9b')
        assert_nil size.validate!
      end

      it "if size is '<1g'" do
        size = subject.new('<1g')
        assert_nil size.validate!
      end

      it "if size is '=1m'" do
        size = subject.new('=1m')
        assert_nil size.validate!
      end
    end

    describe 'is invalid' do
      it "if size is without any operator '1kb'" do
        size = subject.new('1kb')
        error = assert_raises ArgumentError do
          size.validate!
        end
        assert_equal 'Invalid operator: 1', error.message
      end

      it "if size has incorrect metric '>=1gig'" do
        size = subject.new('>=1gig')
        error = assert_raises ArgumentError do
          size.validate!
        end

        assert_equal 'Invalid metric: gig', error.message
      end

      it "if size has invalid number '>=kb'" do
        size = subject.new('>=kb')
        error = assert_raises ArgumentError do
          size.validate!
        end

        assert_equal 'Invalid operator: >=kb', error.message
      end
    end

    it 'to_params returns operator and number in bytes' do
      size = subject.new('>= 1kb')
      assert_equal ['>=', 1024], size.to_params
    end
  end
end
