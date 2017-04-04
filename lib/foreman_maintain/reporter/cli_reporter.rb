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
          @spinner_chars = %w[| / - \\]
          @current_line = ''
          @puts_needed = false
          start_spinner
        end

        def update(line)
          @mutex.synchronize do
            @current_line = line
            print_current_line
          end
        end

        def active?
          @mutex.synchronize { @active }
        end

        def activate
          @mutex.synchronize { @active = true }
          spin
        end

        def deactivate
          return unless active?
          @mutex.synchronize do
            @active = false
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
            print_current_line
            @spinner_index = (@spinner_index + 1) % @spinner_chars.size
          end
        end

        def print_current_line
          @reporter.clear_line
          line = "#{@spinner_chars[@spinner_index]} #{@current_line}"
          @reporter.print(line)
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
        @last_line = ''
      end

      def before_scenario_starts(scenario)
        puts "Running #{scenario.description || scenario.class}"
        hline
      end

      def before_execution_starts(execution)
        puts(execution_info(execution, ''))
      end

      def print(string)
        new_line_if_needed
        @stdout.print(string)
        @stdout.flush
        record_last_line(string)
      end

      def puts(string)
        # we don't print the new line right away, as we want to be able to put
        # the status label at the end of the last line, if possible.
        # Therefore, we just mark that we need to print the new line next time
        # we are printing something.
        new_line_if_needed
        @stdout.print(string)
        @stdout.flush
        @new_line_next_time = true
        record_last_line(string)
      end

      def new_line_if_needed
        if @new_line_next_time
          @stdout.print("\n")
          @stdout.flush
          @new_line_next_time = false
        end
      end

      def with_spinner(message)
        new_line_if_needed
        @spinner.activate
        @spinner.update(message)
        yield @spinner
      ensure
        @spinner.deactivate
        @new_line_next_time = true
      end

      def after_execution_finishes(execution)
        puts_status(execution.status)
        puts(execution.output) if execution.fail?
        hline
        new_line_if_needed
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

      def execution_info(execution, text)
        prefix = "#{execution.name}:"
        "#{prefix} #{text}"
      end

      def puts_status(status)
        label_offset = 10
        padding = @max_length - @last_line.size - label_offset
        if padding < 0
          new_line_if_needed
          padding = @max_length - label_offset
        end
        @stdout.print(' ' * padding + status_label(status))
      end

      def status_label(status)
        mapping = { :success => { :label => '[OK]', :color => :green },
                    :fail => { :label => '[FAIL]', :color => :red },
                    :running => { :label => '[RUNNING]', :color => :blue },
                    :skipped => { :label => '[SKIPPED]', :color => :yellow } }
        properties = mapping[status]
        @hl.color(properties[:label], properties[:color], :bold)
      end

      def hline
        puts @line_char * @max_length
      end

      def record_last_line(string)
        @last_line = string.lines.to_a.last
      end
    end
  end
end
