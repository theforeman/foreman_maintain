require 'thread'
module ForemanMaintain
  # Class responsible for reporting about execution of a scenario
  class Reporter
    # Each public method is a hook called by executor at the specific point
    def before_scenario_starts(_scenario)
    end

    def before_execution_starts(_execution)
    end

    def on_execution_update(_execution, _update)
    end

    def after_execution_finishes(_execution)
    end

    def after_scenario_finishes(_scenario)
    end

    require 'highline'
    class StdoutReporter < Reporter
      # Simple spinner able to keep updating current line
      class Spinner
        def initialize(interval = 0.1)
          @mutex = Mutex.new
          @active = false
          @interval = interval
          @spinner_index = 0
          @spinner_chars = %(|/-\\)
          @current_line = ""
          @puts_needed = false
          @thread = Thread.new do
            loop do
              spin
              sleep @interval
            end
          end
        end

        def update(line)
          @mutex.synchronize { @current_line = line }
        end

        def activate
          @mutex.synchronize { @active = true }
          spin
        end

        def deactivate
          @mutex.synchronize do
            @active = false
            print "\r"
          end
        end

        private
        def spin
          @mutex.synchronize do
            return unless @active
            print "\r"
            print @spinner_chars[@spinner_index]
            print " "
            print @current_line
            @spinner_index = (@spinner_index + 1) % @spinner_chars.size
            @puts_needed = true
          end
        end

      end

      def initialize
        @spinner = Spinner.new
        @hl = HighLine.new
        @max_length = 80
        @line_char = '-'
        @cell_char = '|'
      end

      def before_scenario_starts(scenario)
        puts "Running #{scenario.description || scenario.class}"
        hline
      end

      def before_execution_starts(execution)
        @spinner.update(execution_info(execution, "running"))
        @spinner.activate
      end

      def on_execution_update(execution, update)
        @spinner.update(execution_info(execution, update))
      end

      def after_execution_finishes(execution)
        @spinner.deactivate
        cell(execution_info(execution, status_label(execution, 11), @max_length - 15))
        cell(execution.output) if execution.fail?
        hline
      end

      def after_scenario_finishes(_scenario)
      end

      private

      def execution_info(execution, text, ljust = nil)
        prefix = "#{execution.name}:"
        prefix = prefix.ljust(ljust) if ljust
        "#{prefix} #{text}"
      end

      def status_label(execution, ljust)
        mapping = { :success => { :label => '[OK]', :color => :green },
                    :fail => { :label => '[FAIL]', :color => :red },
                    :running => { :label => '[RUNNING]', :color => :blue },
                    :skipped => { :label => '[SKIPPED]', :color => :yellow } }
        max_length = mapping.values.map { |p| p[:label].size }.max
        properties = mapping[execution.status]
        @hl.color(properties[:label].ljust(ljust), properties[:color], :bold)
      end

      def hline
        puts @line_char * @max_length
      end

      def cell(content)
        print "#{@cell_char} #{content}".ljust(@max_length - 1)
        puts @cell_char
      end
    end
  end
end
