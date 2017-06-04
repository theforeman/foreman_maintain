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

      def initialize(stdout = STDOUT, stdin = STDIN, options = {})
        @stdout = stdout
        @stdin = stdin
        options.validate_options!(:assumeyes)
        @assumeyes = options.fetch(:assumeyes, false)
        @hl = HighLine.new(@stdin, @stdout)
        @max_length = 80
        @line_char = '-'
        @cell_char = '|'
        @spinner = Spinner.new(self)
        @last_line = ''
      end

      def before_scenario_starts(scenario)
        puts "Running #{scenario.description || scenario.class}"
        hline('=')
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

      def ask(message, options = {})
        new_line_if_needed
        options.validate_options!(:password)
        # the answer is confirmed by ENTER which will emit a new line
        @new_line_next_time = false
        @last_line = ''
        # add space at the end as otherwise highline would add new line there :/
        message = "#{message} " unless message =~ /\s\Z/
        answer = @hl.ask(message) { |q| q.echo = false if options[:password] }
        answer.to_s.chomp.downcase if answer
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
        puts(execution.output) unless execution.output.empty?
        hline
        new_line_if_needed
      end

      def after_scenario_finishes(scenario)
        scenario_failure_message(scenario)
        puts "\n"
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
        padding = @max_length - @last_line.to_s.size - label_offset
        if padding < 0
          new_line_if_needed
          padding = @max_length - label_offset
        end
        @stdout.print(' ' * padding + status_label(status))
        @new_line_next_time = true
      end

      def status_label(status)
        mapping = { :success => { :label => '[OK]', :color => :green },
                    :fail => { :label => '[FAIL]', :color => :red },
                    :running => { :label => '[RUNNING]', :color => :blue },
                    :skipped => { :label => '[SKIPPED]', :color => :yellow },
                    :warning => { :label => '[WARNING]', :color => :yellow } }
        properties = mapping[status]
        @hl.color(properties[:label], properties[:color], :bold)
      end

      def hline(line_char = @line_char)
        puts line_char * @max_length
      end

      def record_last_line(string)
        @last_line = string.lines.to_a.last
      end

      private

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def scenario_failure_message(scenario)
        return if scenario.passed?
        message = []
        message << <<-MESSAGE.strip_heredoc
        Scenario [#{scenario.description}] failed.
        MESSAGE
        recommend = []
        steps_with_error = scenario.steps_with_error(:whitelisted => false)
        unless steps_with_error.empty?
          message << <<-MESSAGE.strip_heredoc
          The following steps ended up in failing state:

          #{format_steps(steps_with_error, "\n", 2)}
          MESSAGE
          recommend << <<-MESSAGE.strip_heredoc
          Resolve the failed steps and rerun
          the command. In case the failures are false positives,
          use --whitelist="#{steps_with_error.map(&:label_dashed).join(',')}"
          MESSAGE
        end

        steps_with_warning = scenario.steps_with_warning(:whitelisted => false)
        unless steps_with_warning.empty?
          message << <<-MESSAGE.strip_heredoc
          The following steps ended up in warning state:

          #{format_steps(steps_with_warning, "\n", 2)}
          MESSAGE

          recommend << <<-MESSAGE.strip_heredoc
          The steps in warning state itself might not mean there is an error,
          but it should be reviews to ensure the behavior is expected
          MESSAGE
        end
        puts((message + recommend).join("\n"))
      end

      def format_steps(steps, join_with = ', ', indent = 0)
        steps.map { |s| "#{' ' * indent}[#{s.label_dashed}]" }.join(join_with)
      end
    end
  end
end
