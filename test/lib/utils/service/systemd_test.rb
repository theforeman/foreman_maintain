require 'test_helper'

module ForemanMaintain
  describe Utils::Service::Systemd do
    let(:httpd_service) { ForemanMaintain::Utils::Service::Systemd.new('httpd', 30) }
    let(:crond_service) { ForemanMaintain::Utils::Service::Systemd.new('crond', 20) }
    let(:ntpd_service) { ForemanMaintain::Utils::Service::Systemd.new('ntpd', 10) }
    let(:http_all_service) do
      ForemanMaintain::Utils::Service::Systemd.new('http*', 30, :all => true)
    end

    it 'has name' do
      httpd_service.name.must_equal 'httpd'
    end

    it 'has priority' do
      httpd_service.priority.must_equal 30
    end

    it 'can query the status' do
      status_response = [0, 'systemctl status output']
      httpd_service.stubs(:execute).with('status').returns(status_response)
      httpd_service.status.must_be_kind_of Array
      httpd_service.status.first.must_equal status_response.first
      httpd_service.status.last.must_equal status_response.last
    end

    it 'can generate the system command' do
      File.stubs(:exist?).with('/usr/sbin/service-wait').returns(true)
      httpd_service.command('status').must_equal 'service-wait httpd status'
    end

    it 'can generate the system command without waiting' do
      httpd_service.command('status', :wait => false).must_equal 'systemctl status httpd'
    end

    it 'can generate the system command when service-wait is not present' do
      File.stubs(:exist?).with('/usr/sbin/service-wait').returns(false)
      httpd_service.command('status').must_equal 'systemctl status httpd'
    end

    it 'returns the output along with status after execution' do
      status_response = [0, 'systemctl status output']
      ForemanMaintain::Utils::SystemHelpers.any_instance.expects(:execute_with_status).
        with('systemctl status httpd').returns(status_response)
      httpd_service.send(:execute, 'status', :wait => false).must_equal status_response
    end

    it 'can tell if it is running' do
      status_response = [0, 'systemctl status output']
      httpd_service.stubs(:execute).with('status').returns(status_response)
      httpd_service.running?.must_equal true
    end

    it 'can tell if it is not running' do
      status_response = [1, 'service failed']
      httpd_service.stubs(:execute).with('status').returns(status_response)
      httpd_service.running?.must_equal false
    end

    it 'can tell if the service exist' do
      httpd_service.respond_to?(:exist?).must_equal true
    end

    it 'interpolates to its name' do
      httpd_service.to_s.must_equal 'httpd'
    end

    it 'inspects itself nicely' do
      httpd_service.inspect.must_equal 'Systemd(httpd [30])'
    end

    it 'is sortable' do
      services = [httpd_service, crond_service, httpd_service, ntpd_service]
      services.sort.must_equal [ntpd_service, crond_service, httpd_service, httpd_service]
    end

    it 'starts the service' do
      start_response = [0, '']
      httpd_service.stubs(:execute).with('start').returns(start_response)
      httpd_service.start.must_equal start_response
    end

    it 'stops the service' do
      stop_response = [0, '']
      httpd_service.stubs(:execute).with('stop').returns(stop_response)
      httpd_service.stop.must_equal stop_response
    end

    it 'enables the service' do
      enable_response = [0, '']
      httpd_service.stubs(:execute).with('enable', :wait => false).returns(enable_response)
      httpd_service.enable.must_equal enable_response
    end

    it 'disables the service' do
      disable_response = [0, '']
      httpd_service.stubs(:execute).with('disable', :wait => false).returns(disable_response)
      httpd_service.disable.must_equal disable_response
    end

    it 'starts service with --all' do
      start_response = [0, '']
      http_all_service.stubs(:execute).with('start').returns(start_response)
      http_all_service.start.must_equal start_response
    end

    describe 'matches?' do
      it 'can compare by name' do
        httpd_service.matches?('httpd').must_equal true
        crond_service.matches?('httpd').must_equal false
      end

      it 'can compare by service' do
        httpd_service.matches?(httpd_service).must_equal true
        crond_service.matches?(httpd_service).must_equal false
      end

      it 'can compare with other obejcts' do
        httpd_service.matches?(nil).must_equal false
      end
    end
  end
end
