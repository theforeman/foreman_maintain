module ForemanMaintain
  class ReportRunner
    class Yaml < ReportRunner
      def print_result
        puts @result.to_yaml
      end
    end
  end
end
