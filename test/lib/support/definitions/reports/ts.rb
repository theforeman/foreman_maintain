module Reports
  module Table
    class Sizes < ForemanMaintain::Report
      metadata do
        label :table_sizes
        description 'Get table sizes'
        param :size, 'Show tables with size greater than equal to specified', :array => true
      end
    end
  end
end
