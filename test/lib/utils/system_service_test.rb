require 'test_helper'

module ForemanMaintain
  describe '#system_service' do
    class FakeFeature; end
    let(:fake_feature) { FakeFeature.new }
    it 'can create normal system service object' do
      service = ForemanMaintain::Utils.system_service('serviced', 30)
      service.must_be_instance_of ForemanMaintain::Utils::SystemService
      service.name.must_equal 'serviced'
      service.priority.must_equal 30
    end

    it 'creates RemoteDBService for remote postgres' do
      fake_feature.stubs(:local?).returns(false)
      service = ForemanMaintain::Utils.system_service(
        'postgresql', 30, :component => 'Foreman', :db_feature => fake_feature
      )
      service.must_be_instance_of ForemanMaintain::Utils::RemoteDBService
      service.name.must_equal 'postgresql'
      service.priority.must_equal 30
      service.component.must_equal 'Foreman'
      service.db_feature.must_equal fake_feature
    end

    it 'creates SystemService for local postgres' do
      fake_feature.stubs(:local?).returns(true)
      service = ForemanMaintain::Utils.system_service(
        'postgresql', 30, :component => 'Foreman', :db_feature => fake_feature
      )
      service.must_be_instance_of ForemanMaintain::Utils::SystemService
      service.name.must_equal 'postgresql'
      service.priority.must_equal 30
    end

    it 'creates RemoteDBService for remote mongo' do
      fake_feature.stubs(:local?).returns(false)
      service = ForemanMaintain::Utils.system_service(
        'rh-mongodb34-mongod', 30, :db_feature => fake_feature
      )
      service.must_be_instance_of ForemanMaintain::Utils::RemoteDBService
    end

    it 'creates SystemService for local mongo' do
      fake_feature.stubs(:local?).returns(true)
      service = ForemanMaintain::Utils.system_service(
        'rh-mongodb34-mongod', 30, :db_feature => fake_feature
      )
      service.must_be_instance_of ForemanMaintain::Utils::SystemService
    end
  end

  describe Utils::SystemService do
    let(:httpd_service) { ForemanMaintain::Utils::SystemService.new('httpd', 30) }
    let(:crond_service) { ForemanMaintain::Utils::SystemService.new('crond', 20) }
    let(:ntpd_service) { ForemanMaintain::Utils::SystemService.new('ntpd', 10) }

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
      httpd_service.inspect.must_equal 'SystemService(httpd [30])'
    end

    it 'is sortable' do
      services = [crond_service, httpd_service, ntpd_service]
      services.sort.must_equal [ntpd_service, crond_service, httpd_service]
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

  describe Utils::RemoteDBService do
    class LocalDBFeature < Feature
      def local?
        true
      end
    end

    class RemoteDBFeature < Feature
      def local?
        false
      end

      def ping
        true
      end
    end

    class RemoteStoppedDBFeature < Feature
      def local?
        false
      end

      def ping
        false
      end
    end

    let(:remote_db_feature) { RemoteDBFeature.new }
    let(:remote_db_service) do
      ForemanMaintain::Utils::RemoteDBService.new(
        'mongod', 10, :component => 'Pulp', :db_feature => remote_db_feature
      )
    end
    let(:remote_db_service_no_comp) do
      ForemanMaintain::Utils::RemoteDBService.new(
        'mongod', 10, :db_feature => RemoteDBFeature.new
      )
    end
    let(:remote_stopped_db_service) do
      ForemanMaintain::Utils::RemoteDBService.new(
        'mongod', 10, :component => 'Pulp', :db_feature => RemoteStoppedDBFeature.new
      )
    end

    it 'has component' do
      remote_db_service_no_comp.component.must_be_nil
      remote_db_service.component.must_equal 'Pulp'
    end

    it 'has db_feature' do
      remote_db_service.db_feature.must_equal remote_db_feature
    end

    it 'interpolates to its name' do
      remote_db_service_no_comp.to_s.must_equal 'mongod'
      remote_db_service.to_s.must_equal 'mongod (Pulp)'
    end

    it 'inspects itself nicely' do
      remote_db_service.inspect.must_equal 'RemoteDBService(mongod:Pulp [10])'
      remote_db_service_no_comp.inspect.must_equal 'RemoteDBService(mongod [10])'
    end

    it 'can tell the status for remote DB' do
      remote_db_service.status.must_equal [0, 'mongod (Pulp) is remote and is UP.']
    end

    it 'prevents remote db from disabling' do
      result = [0, "mongod (Pulp) is remote and is UP. It can't be disabled."]
      remote_db_service.disable.must_equal result
    end

    it 'prevents remote db from enabling' do
      result = [0, "mongod (Pulp) is remote and is UP. It can't be enabled."]
      remote_db_service.enable.must_equal result
    end

    it 'can tell if the remote db is running' do
      remote_db_service.running?.must_equal true
      remote_stopped_db_service.running?.must_equal false
    end

    it 'can handle remote db start' do
      remote_db_service.start.must_equal [0, 'mongod (Pulp) is remote and is UP.']
      remote_stopped_db_service.start.must_equal [1, 'mongod (Pulp) is remote and is DOWN.']
    end

    it 'can handle remote db stop' do
      remote_db_service.stop.must_equal [0, 'mongod (Pulp) is remote and is UP.']
      remote_stopped_db_service.stop.must_equal [0, 'mongod (Pulp) is remote and is DOWN.']
    end

    describe 'matches?' do
      let(:mongod_service) { ForemanMaintain::Utils::SystemService.new('mongod', 10) }

      it 'can compare by name' do
        remote_db_service.matches?('mongod').must_equal true
        remote_db_service.matches?('httpd').must_equal false
      end

      it 'can compare by service' do
        remote_db_service.matches?(remote_db_service).must_equal true
        remote_db_service.matches?(mongod_service).must_equal false
      end
    end
  end
end
