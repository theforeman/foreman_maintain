require 'test_helper'
require 'foreman_maintain/csv_parser'

describe ForemanMaintain::CSVParser do
  describe 'parse' do
    let(:parser) { ForemanMaintain::CSVParser.new }

    it 'parses nil' do
      _(parser.parse(nil)).must_equal []
    end

    it 'parses empty string' do
      _(parser.parse('')).must_equal ['']
    end

    it 'parses single value' do
      _(parser.parse('a')).must_equal ['a']
    end

    it 'parses a dquoted string' do
      _(parser.parse('\"a')).must_equal ['"a']
    end

    it 'parses a quoted string' do
      _(parser.parse("Mary\\'s")).must_equal ["Mary's"]
    end

    it 'should parse a comma separated string' do
      _(parser.parse('a,b,c')).must_equal %w[a b c]
    end

    it 'parses a string with escaped comma' do
      _(parser.parse('a\,b,c')).must_equal %w[a,b c]
    end

    it 'should parse a comma separated string with quotes' do
      _(parser.parse('a,b,\\"c\\"')).must_equal ['a', 'b', '"c"']
    end

    it 'parses a comma separated string with values including comma' do
      _(parser.parse('a,b,"c,d"')).must_equal %w[a b c,d]
    end

    it 'parses a comma separated string with values including comma (dquotes)' do
      _(parser.parse("a,b,'c,d'")).must_equal %w[a b c,d]
    end

    it 'raises quoting error' do
      assert_raises(ArgumentError, 'Illegal quoting in "3,4""s') do
        parser.parse('1,"3,4""s')
      end
    end
  end
end
