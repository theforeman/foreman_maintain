require 'forwardable'
require 'json'
require 'logger'
require 'yaml'
require 'timeout'

module ForemanMaintain
  require 'foreman_maintain/core_ext'
  require 'foreman_maintain/concerns/logger'
  require 'foreman_maintain/concerns/reporter'
  require 'foreman_maintain/concerns/finders'
  require 'foreman_maintain/concerns/metadata'
  require 'foreman_maintain/concerns/scenario_metadata'
  require 'foreman_maintain/concerns/os_facts'
  require 'foreman_maintain/concerns/system_helpers'
  require 'foreman_maintain/concerns/system_service'
  require 'foreman_maintain/concerns/hammer'
  require 'foreman_maintain/concerns/base_database'
  require 'foreman_maintain/concerns/directory_marker'
  require 'foreman_maintain/concerns/versions'
  require 'foreman_maintain/concerns/downstream'
  require 'foreman_maintain/concerns/foreman_and_katello_version_map'
  require 'foreman_maintain/concerns/upstream'
  require 'foreman_maintain/concerns/primary_checks'
  require 'foreman_maintain/concerns/pulp_common'
  require 'foreman_maintain/concerns/firewall/iptables_maintenance_mode'
  require 'foreman_maintain/concerns/firewall/nftables_maintenance_mode'
  require 'foreman_maintain/concerns/firewall/maintenance_mode'
  require 'foreman_maintain/top_level_modules'
  require 'foreman_maintain/yaml_storage'
  require 'foreman_maintain/config'
  require 'foreman_maintain/context'
  require 'foreman_maintain/detector'
  require 'foreman_maintain/dependency_graph'
  require 'foreman_maintain/param'
  require 'foreman_maintain/feature'
  require 'foreman_maintain/executable'
  require 'foreman_maintain/check'
  require 'foreman_maintain/report'
  require 'foreman_maintain/procedure'
  require 'foreman_maintain/scenario'
  require 'foreman_maintain/runner'
  require 'foreman_maintain/upgrade_runner'
  require 'foreman_maintain/reporter'
  require 'foreman_maintain/package_manager'
  require 'foreman_maintain/repository_manager'
  require 'foreman_maintain/utils'
  require 'foreman_maintain/error'

  class << self
    include ForemanMaintain::Concerns::PrimaryChecks
    attr_accessor :config, :logger

    LOGGER_LEVEL_MAPPING = {
      'debug' => ::Logger::DEBUG,
      'info' => ::Logger::INFO,
      'warn' => ::Logger::WARN,
      'error' => ::Logger::ERROR,
      'fatal' => ::Logger::FATAL,
      'unknown' => ::Logger::UNKNOWN,
    }.freeze

    def setup(options = {})
      set_home_environment

      # using a queue, we can log the messages which are generated before initializing logger
      self.config = Config.new(options)
      configure_highline
      load_definitions
      init_logger
      update_path
    end

    def set_home_environment
      ENV['HOME'] ||= '/root'
    end

    # Appending PATH with expected paths needed for commands we run
    def update_path
      paths = ['/sbin']
      existing_paths = ENV['PATH'].split(':')
      paths -= existing_paths
      if paths.any?
        paths = paths.join(':').chomp(':')
        ENV['PATH'] = "#{ENV['PATH']}:#{paths}"
      end
    end

    def config_file
      config.config_file
    end

    def load_definitions
      # we need to add the load paths first, in case there is crossreferencing
      # between the definitions directories
      $LOAD_PATH.concat(config.definitions_dirs)
      config.definitions_dirs.each do |definitions_dir|
        file_paths = File.expand_path(File.join(definitions_dir, '**', '*.rb'))
        Dir.glob(file_paths).sort.each { |f| require f }
      end
    end

    def configure_highline
      HighLine.use_color = config.use_color?
    end

    def cache
      ObjectCache.instance
    end

    def detector
      @detector ||= Detector.new
    end

    def refresh_features
      @detector = Detector.new
    end

    def reporter
      @reporter ||= ForemanMaintain::Reporter::CLIReporter.new
    end

    def available_features(*args)
      detector.available_features(*args)
    end

    def available_scenarios(*args)
      detector.available_scenarios(*args)
    end

    def available_checks(*args)
      detector.available_checks(*args)
    end

    def available_reports(*args)
      detector.available_reports(*args)
    end

    def available_procedures(*args)
      detector.available_procedures(*args)
    end

    def allowed_available_procedures(*args)
      procedures = detector.available_procedures(*args)
      procedures.select(&:advanced_run?)
    end

    def init_logger
      # convert size in KB to Bytes
      log_fsize = config.log_file_size.to_i * 1024
      @logger = Logger.new(config.log_filename, 10, log_fsize).tap do |logger|
        logger.level = LOGGER_LEVEL_MAPPING[config.log_level] || Logger::INFO
        logger.datetime_format = '%Y-%m-%d %H:%M:%S%z '
      end
      pickup_log_messages
    end

    def pickup_log_messages
      return if config.pre_setup_log_messages.empty?
      config.pre_setup_log_messages.each { |msg| logger.info msg }
      config.pre_setup_log_messages.clear
    end

    def storage(label = :default)
      ForemanMaintain::YamlStorage.load(label)
    rescue StandardError => e
      logger.error "Invalid Storage label i.e #{label}. Error - #{e.message}"
    end

    def upgrade_in_progress
      storage[:upgrade_target_version]
    end

    def pkg_and_cmd_name
      instance_feature = ForemanMaintain.available_features(:label => :instance).first
      if instance_feature.downstream
        return instance_feature.downstream.fm_pkg_and_cmd_name
      end

      [main_package_name, 'foreman-maintain']
    end

    def command_name
      pkg_and_cmd_name[1]
    end

    def perform_self_upgrade
      package_name, command = pkg_and_cmd_name
      packages_to_update = [package_name, main_package_name].uniq
      packages_to_update_str = packages_to_update.join(', ')

      puts "Checking for new version of #{packages_to_update_str}..."

      package_manager = ForemanMaintain.package_manager

      if package_manager.update_available?(packages_to_update)
        puts "\nUpdating #{packages_to_update_str}."
        package_manager.update(packages_to_update, :assumeyes => true)
        puts "\nSuccessfully updated #{packages_to_update_str}."\
             "\nRe-run #{command} with required options!"
        exit 75
      end
      puts "Nothing to update, can't find new version of #{packages_to_update_str}."
    end

    def main_package_name
      el? ? 'rubygem-foreman_maintain' : 'ruby-foreman-maintain'
    end
  end
end
