module ForemanMaintain
  class Reporter
    class PlainTextReporter < CLIReporter
      def before_scenario_starts(_scenario)
        puts "\nGenerating report"
        hline('=')
      end

      def before_execution_starts(execution)
        puts @hl.color(execution.name, :bold)
      end

      def after_execution_finishes(execution)
        puts(execution.output) unless execution.output.empty?
        hline
        new_line_if_needed
      end
    end
  end
end
