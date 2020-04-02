require File.expand_path('../test_helper', File.dirname(__FILE__))
require File.expand_path('assume_feature_dependencies_helper', File.dirname(__FILE__))
module DefinitionsTestHelper
  include ForemanMaintain::Concerns::Finders
  include ForemanMaintain::Concerns::SystemService
  include ForemanMaintain::Concerns::SystemHelpers
  include AssumeFeatureDependenciesHelper

  def detector
    @detector ||= ForemanMaintain.detector
  end

  def feature_class(feature_label)
    feature_class = detector.send(:autodetect_features)[feature_label.to_sym].first
    raise "Feature #{feature_label} not present in autodetect features" unless feature_class

    feature_class
  end

  def assume_feature_present(feature_label, stubs = nil)
    feature_class = self.feature_class(feature_label)
    feature_class.stubs(:present? => true)
    feature_class.any_instance.stubs(stubs) if stubs
    yield feature_class if block_given?
  end

  def assume_feature_absent(feature_label)
    feature_class = self.feature_class(feature_label)
    feature_class.stubs(:present? => false)
  end

  def log_reporter
    @log_reporter
  end

  def reset_reporter
    @log_reporter = Support::LogReporter.new
    ForemanMaintain.stubs(:reporter).returns(@log_reporter)
  end

  def run_step(step)
    ForemanMaintain::Runner::Execution.new(step, @log_reporter).tap(&:run)
  end

  def assert_stdout(expected_output)
    assert_equal expected_output.strip, log_reporter.output.strip
  end

  alias run_check run_step
  alias run_procedure run_step

  def mock_with_spinner(definition)
    mock_spinner = MiniTest::Mock.new
    mock_spinner.expect(:update, nil)

    definition.stubs(:with_spinner).returns(mock_spinner)
    mock_spinner
  end

  def stub_systemctl_calls(services, action)
    services.each do |service|
      service.stubs(action.to_sym).returns([0, "#{action} succeeded."])
    end
  end

  def version(version_str)
    ForemanMaintain::Concerns::SystemHelpers::Version.new(version_str)
  end

  def setup
    reset_reporter
    PackageManagerTestHelper.mock_package_manager
  end

  def teardown
    detector.refresh
  end

  # given the current feature assumptions (see assume_feature_present and
  # assume_feature_absent), assert the scenario with given filter is considered
  # present
  def assert_scenario(filter, sat_version)
    scenario = find_scenarios(filter).select(&matching_version_check(sat_version)).first
    assert scenario, "Expected the scenario #{filter} to be present"
    scenario
  end

  def matching_version_check(sat_version)
    proc do |scenario|
      scenario.respond_to?(:target_version) && scenario.target_version == sat_version
    end
  end

  # given the current feature assumptions (see assume_feature_present and
  # assume_feature_absent), assert the scenario with given filter is considered
  # absent
  def refute_scenario(filter, version)
    scenario = find_scenarios(filter).select(&matching_version_check(version)).first
    refute scenario, "Expected the scenario #{filter} to be absent"
  end

  def hammer_config_dirs(dirs)
    Features::Hammer.any_instance.stubs(:config_directories).returns(dirs)
  end

  def installer_config_dir(dirs)
    Features::Installer.any_instance.stubs(:config_directory).returns(dirs)
  end

  def stub_foreman_proxy_config
    settings_file = '/etc/foreman-proxy/settings.yml'
    Features::ForemanProxy.any_instance.stubs(
      :lookup_dhcpd_config_file => '/etc/dhcp/dhcpd.conf',
      :lookup_into => settings_file,
      :settings_file => settings_file,
      :load_proxy_settings => {},
      :dhcpd_conf_exist? => true,
      :features => ['dhcp']
    )
  end

  def mock_installer_package(package)
    Features::Installer.any_instance.stubs(:find_package).returns(nil)
    Features::Installer.any_instance.stubs(:find_package).with do |args|
      args == package
    end.returns(package)
  end

  def existing_system_service(name, priority, options = {})
    service = system_service(name, priority, options)
    service.stubs(:exist?).returns(true)
    service
  end

  def missing_system_service(name, priority, options = {})
    service = system_service(name, priority, options)
    service.stubs(:exist?).returns(false)
    service
  end

  def mock_service(name, priority = 30)
    service = ForemanMaintain::Utils::Service::Systemd.new(name, priority)
    service.stubs(:execute).raises(
      RuntimeError, "Mocked service can't execute system commads. Stub your method properly."
    )
    yield service if block_given?
    ForemanMaintain::Utils.stubs(:system_service).with(name, priority).returns(service)
    service
  end

  def mock_net_http_response(code, body)
    response = mock('response')
    response.stubs(:code).returns(code.to_s)
    response.stubs(:body).returns(JSON.dump(body))
    response
  end

  def assume_service_running(name, priority = 30)
    mock_service(name, priority) do |service|
      service.stubs(:status).returns([0, 'OK'])
      service.stubs(:exist?).returns(true)
      yield service if block_given?
    end
  end

  def assume_service_stopped(name, priority = 30)
    mock_service(name, priority) do |service|
      service.stubs(:status).returns([1, 'STOPPED'])
      service.stubs(:exist?).returns(true)
      yield service if block_given?
    end
  end

  def assume_service_missing(name, priority = 30)
    mock_service(name, priority) do |service|
      service.stubs(:exist?).returns(false)
      yield service if block_given?
    end
  end
end

TEST_DIR = File.dirname(__FILE__)
CONFIG_FILE = File.join(TEST_DIR, 'config/foreman_maintain.yml.test').freeze

ForemanMaintain.setup
