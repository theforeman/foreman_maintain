require 'fileutils'
module ForemanMaintain
  class Config
    attr_accessor :definitions_dirs, :log_level, :log_dir, :storage_file

    def initialize(options = {})
      @definitions_dirs = options.fetch(:definitions_dirs,
                                        [File.join(source_path, 'definitions')])

      @log_level = options.fetch(:log_level, ::Logger::DEBUG)
      @log_dir = find_log_dir_path(options.fetch(:log_dir, 'log'))
      @storage_file = options.fetch(:storage_file, 'data.yml')
    end

    private

    def source_path
      File.expand_path('../../..', __FILE__)
    end

    def find_log_dir_path(log_dir)
      log_dir_path = File.expand_path(log_dir)
      begin
        FileUtils.mkdir_p(log_dir_path, :mode => 0o750) unless File.exist?(log_dir_path)
      rescue => e
        $stderr.puts "No permissions to create log dir #{log_dir}"
        $stderr.puts e.message.inspect
      end
      log_dir_path
    end
  end
end
