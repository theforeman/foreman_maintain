module Reports
  module Table
    class Sizes < ForemanMaintain::Report
      metadata do
        label :table_sizes
        description 'Get table sizes'
        param :size, 'Show tables with size greater than equal to specified', :array => true
      end

      attr_reader :size

      DEFAULT_LIMIT_IN_BYTES = Numeric::CONVERSION_NORMS[:m]
      DEFAULT_OP = '>='.freeze

      def run
        puts feature(:foreman_database).size(*size_args)
      end

      def to_h
        csv_data = feature(:foreman_database).size(*size_args)
        parsed = CSV.parse(csv_data, :col_sep => '|')

        stats = parsed[2, parsed.count - 3].inject({}) do |stat, row|
          stat.merge(row.first.strip => row[1].strip)
        end

        { label => stats }
      end

      private

      def size_args
        return default_options if size.nil? || size.empty?
        size
      end

      def default_options
        [DEFAULT_OP, DEFAULT_LIMIT_IN_BYTES]
      end
    end
  end
end
