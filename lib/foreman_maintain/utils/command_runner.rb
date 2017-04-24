require 'English'
require 'tempfile'

module ForemanMaintain
  module Utils
    # Wrapper around running a command
    class CommandRunner
      attr_reader :logger, :command

      def initialize(logger, command, options)
        options.validate_options!(:stdin, :hidden_patterns, :interactive)
        @logger = logger
        @command = command
        @stdin = options[:stdin]
        @hidden_patterns = Array(options[:hidden_patterns])
        @interactive = options[:interactive]
        @options = options
        raise ArgumentError, 'Can not pass stdin for interactive command' if @interactive && @stdin
      end

      def run
        logger.debug(hide_strings("Running command #{@command} with stdin #{@stdin.inspect}"))
        if @interactive
          run_interactively
        else
          run_non_interactively
        end
        logger.debug("output of the command:\n #{hide_strings(output)}")
      end

      def interactive?
        @interactive
      end

      def output
        raise 'Command not yet executed' unless defined? @output
        @output
      end

      def exit_status
        raise 'Command not yet executed' unless defined? @exit_status
        @exit_status
      end

      def success?
        exit_status == 0
      end

      def execution_error
        raise Error::ExecutionError.new(hide_strings(@command),
                                        exit_status,
                                        hide_strings(@stdin),
                                        @interactive ? nil : hide_strings(@output))
      end

      private

      # rubocop:disable Metrics/AbcSize
      def run_interactively
        # use tmp files to capture output and exit status of the command when
        # running interactively
        log_file = Tempfile.open('captured-output')
        exit_file = Tempfile.open('captured-exit-code')
        Kernel.system("script -qc '#{full_command}; echo $? > #{exit_file.path}' #{log_file.path}")
        File.open(log_file.path) { |f| @output = f.read }
        File.open(exit_file.path) do |f|
          exit_status = f.read.strip
          @exit_status = if exit_status.empty?
                           256
                         else
                           exit_status.to_i
                         end
        end
      ensure
        log_file.close
        exit_file.close
      end

      def run_non_interactively
        IO.popen(full_command, 'r+') do |f|
          if @stdin
            f.puts(@stdin)
            f.close_write
          end
          @output = f.read.strip
        end
        @exit_status = $CHILD_STATUS.exitstatus
      end

      def full_command
        "#{@command} 2>&1"
      end

      def hide_strings(string)
        @hidden_patterns.reduce(string) do |result, hidden_pattern|
          result.gsub(hidden_pattern, '[FILTERED]')
        end
      end
    end
  end
end
