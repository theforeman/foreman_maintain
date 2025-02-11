require 'open3'
require 'tempfile'

module ForemanMaintain
  module Utils
    # Wrapper around running a command
    class CommandRunner
      attr_reader :logger, :command

      def initialize(logger, command, options)
        options.validate_options!(:stdin, :interactive, :valid_exit_statuses, :env, :merge_stderr)
        options[:valid_exit_statuses] ||= [0]
        options[:env] ||= {}
        @logger = logger
        @command = command
        @stdin = options[:stdin]
        @interactive = options[:interactive]
        @options = options
        @valid_exit_statuses = options[:valid_exit_statuses]
        @env = options[:env]
        @merge_stderr = options.fetch(:merge_stderr, true)
        raise ArgumentError, 'Can not pass stdin for interactive command' if @interactive && @stdin
      end

      def run
        logger&.debug("Running command #{@command} with stdin #{@stdin.inspect}")
        if @interactive
          run_interactively
        else
          run_non_interactively
        end
        logger&.debug("output of the command:\n #{output}")
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

      def stderr
        raise 'Command not yet executed' unless defined? @stderr
        @stderr
      end

      def success?
        @valid_exit_statuses.include? exit_status
      end

      def execution_error
        raise Error::ExecutionError.new(@command,
          exit_status,
          @stdin,
          @interactive ? nil : @output)
      end

      private

      def run_interactively
        # use tmp files to capture output and exit status of the command when
        # running interactively
        log_file = Tempfile.open('captured-output')
        exit_file = Tempfile.open('captured-exit-code')
        Kernel.system(
          "stdbuf -oL -eL bash -c '#{full_command}; echo $? > #{exit_file.path}'"\
          "| tee -i #{log_file.path}"
        )
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
        @output, @stderr, status = Open3.capture3(@env, full_command, :stdin_data => @stdin)
        @exit_status = status.exitstatus
      end

      def full_command
        if @merge_stderr
          "#{@command} 2>&1"
        else
          @command
        end
      end
    end
  end
end
