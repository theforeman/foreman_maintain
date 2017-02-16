require 'thread'
require 'highline'

module ForemanMaintain
  class Reporter
    class CLIReporter < Reporter
      # Simple spinner able to keep updating current line
      class Spinner
        def initialize(reporter, interval = 0.1)
          @reporter = reporter
          @mutex = Mutex.new
          @active = false
          @interval = interval
          @spinner_index = 0
          @spinner_chars = %w(| / - \\)
          @current_line = ''
          @puts_needed = false
          start_spinner
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
            @reporter.print "\r"
          end
        end

        private

        def start_spinner
          @thread = Thread.new do
            loop do
              spin
              sleep @interval
            end
          end
        end

        def spin
          @mutex.synchronize do
            return unless @active
            @reporter.clear_line
            @reporter.print "\r"
            line = "#{@spinner_chars[@spinner_index]} #{@current_line}"
            @reporter.print(line)
            @spinner_index = (@spinner_index + 1) % @spinner_chars.size
          end
        end
      end

      def initialize(stdout = STDOUT, stdin = STDIN)
        @stdout = stdout
        @stdin = stdin
        @hl = HighLine.new
        @max_length = 80
        @line_char = '-'
        @cell_char = '|'
        @spinner = Spinner.new(self)
      end

      def before_scenario_starts(scenario)
        puts "Running #{scenario.description || scenario.class}"
        hline
      end

      def before_execution_starts(execution)
        @spinner.update(execution_info(execution, 'running'))
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

      def after_scenario_finishes(_scenario); end

      def on_next_steps(runner, steps)
        choice = if steps.size > 1
                   multiple_steps_selection(steps)
                 elsif ask_to_confirm("Continue with step [#{steps.first.description}]?")
                   steps.first
                 else
                   :quit
                 end
        choice == :quit ? runner.ask_to_quit : runner.add_step(choice)
      end

      def multiple_steps_selection(steps)
        puts 'There are multiple steps to proceed:'
        steps.each_with_index do |step, index|
          puts "#{index + 1}) #{step.description}"
        end
        ask_to_select('Select step to continue', steps, &:description)
      end

      def ask_to_confirm(message)
        print "#{message}, [yN]"
        answer = @stdin.gets.chomp
        case answer
        when 'y'
          true
        when 'n'
          false
        end
      ensure
        clear_line
      end

      def ask_to_select(message, steps)
        print "#{message}, (q) for quit"
        answer = @stdin.gets.chomp
        case answer
        when 'q'
          :quit
        when /^\d+$/
          steps[answer.to_i - 1]
        end
      ensure
        clear_line
      end

      def clear_line
        print "\r" + ' ' * @max_length + "\r"
      end

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

      def print(string)
        @stdout.print(string)
        @stdout.flush
      end

      def puts(string)
        @stdout.puts(string)
        @stdout.flush
      end
    end
  end
end
