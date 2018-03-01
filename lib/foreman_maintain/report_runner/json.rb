module ForemanMaintain
  class ReportRunner
    class Json < ReportRunner
      def print_result
        puts JSON.pretty_generate(@result)
      end
    end
  end
end
