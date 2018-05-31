require 'English'
require 'tempfile'

module ForemanMaintain
  module Utils
    # Wrapper around running a command
    class CommandRunner
      attr_reader :logger, :command

      def initialize(logger, command, options)
        options.validate_options!(:stdin, :hidden_patterns, :interactive, :valid_exit_statuses)
        options[:valid_exit_statuses] ||= [0]
        @logger = logger
        @command = command
        @stdin = options[:stdin]
        @hidden_patterns = Array(options[:hidden_patterns]).compact
        @interactive = options[:interactive]
        @options = options
        @valid_exit_statuses = options[:valid_exit_statuses]
        raise ArgumentError, 'Can not pass stdin for interactive command' if @interactive && @stdin
      end

      def run(&block)
        if logger
          logger.debug(hide_strings("Running command #{@command} with stdin #{@stdin.inspect}"))
        end
        if @interactive
          run_interactively
        else
          run_non_interactively(&block)
        end
        logger.debug("output of the command:\n #{hide_strings(output)}") if logger
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
        @valid_exit_statuses.include? exit_status
      end

      def execution_error
        raise Error::ExecutionError.new(hide_strings(@command),
                                        exit_status,
                                        hide_strings(@stdin),
                                        @interactive ? nil : hide_strings(@output))
      end

      private

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

      def run_non_interactively(&block)
        IO.popen(full_command, 'r+') do |f|
          if @stdin
            f.puts(@stdin)
            f.close_write
          end
          @output = with_line_streaming(f, &block).strip
        end
        @exit_status = $CHILD_STATUS.exitstatus
      end

      def full_command
        "#{@command} 2>&1"
      end

      def with_line_streaming(io)
        output = if block_given?
                   result = []
                   io.each_line.lazy.each do |line|
                     result << line
                     yield line.strip
                   end
                   result.join
                 else
                   io.read
                 end
        output
      end

      def hide_strings(string)
        return unless string
        @hidden_patterns.reduce(string) do |result, hidden_pattern|
          result.gsub(hidden_pattern, '[FILTERED]')
        end
      end
    end
  end
end
