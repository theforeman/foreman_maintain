require 'test_helper'

describe 'Service procedures perform appropiate actions' do
  include DefinitionsTestHelper

  before do
    @services = %w[tomcat qpidd httpd squid].map do |s|
      ForemanMaintain::Utils.system_service(s, 10)
    end
    Features::Service.any_instance.stubs(:filtered_services).returns(@services)

    assume_satellite_present do |feature_class|
      feature_class.any_instance.stubs(:less_than_version? => false)
    end
  end

  describe 'Stop services procedure runs successfully' do
    subject do
      Procedures::Service::Stop.new
    end

    it 'Stops Services' do
      stub_systemctl_calls(@services, 'stop')
      result = run_procedure(subject)
      puts result.output
      assert result.success?
    end
  end

  describe 'Start services procedure runs successfully' do
    subject do
      Procedures::Service::Start.new
    end

    it 'Starts services' do
      stub_systemctl_calls(@services, 'start')
      result = run_procedure(subject)
      assert result.success?
    end
  end

  describe 'Enable services procedure runs successfully' do
    subject do
      Procedures::Service::Enable.new
    end

    it 'Enables services' do
      stub_systemctl_calls(@services, 'enable')
      result = run_procedure(subject)
      assert result.success?
    end
  end

  describe 'Disable services procedure runs successfully' do
    subject do
      Procedures::Service::Disable.new
    end

    it 'Disables services' do
      stub_systemctl_calls(@services, 'disable')
      result = run_procedure(subject)
      assert result.success?
    end
  end

  describe 'Service status procedure runs successfully' do
    subject do
      Procedures::Service::Status.new
    end

    it 'Displays service status' do
      stub_systemctl_calls(@services, 'status')
      result = run_procedure(subject)
      assert result.success?
    end
  end

  describe 'Service restart procedure runs successfully' do
    subject do
      Procedures::Service::Restart.new
    end

    it 'Stops and starts services' do
      stub_systemctl_calls(@services, 'stop')
      stub_systemctl_calls(@services, 'start')
      result = run_procedure(subject)
      assert result.success?
    end
  end

  describe 'Service list runs successfully' do
    subject do
      Procedures::Service::List.new
    end

    it 'Lists services' do
      result = run_procedure(subject)
      assert result.success?
    end
  end
end
