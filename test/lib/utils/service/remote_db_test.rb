require 'test_helper'

module ForemanMaintain
  describe Utils::Service::RemoteDB do
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
      ForemanMaintain::Utils::Service::RemoteDB.new(
        'mongod', 10, :component => 'Pulp', :db_feature => remote_db_feature
      )
    end
    let(:remote_db_service_no_comp) do
      ForemanMaintain::Utils::Service::RemoteDB.new(
        'mongod', 10, :db_feature => RemoteDBFeature.new
      )
    end
    let(:remote_stopped_db_service) do
      ForemanMaintain::Utils::Service::RemoteDB.new(
        'mongod', 10, :component => 'Pulp', :db_feature => RemoteStoppedDBFeature.new
      )
    end

    def stub_psql_cmd_available?(kclass, ret_value)
      kclass.any_instance.stubs(:psql_cmd_available?).returns(ret_value)
    end

    def stub_ping(kclass, ret_value)
      kclass.any_instance.stubs(:ping).returns(ret_value)
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
      remote_db_service.inspect.must_equal 'RemoteDB(mongod:Pulp [10])'
      remote_db_service_no_comp.inspect.must_equal 'RemoteDB(mongod [10])'
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
      stub_psql_cmd_available?(RemoteStoppedDBFeature, true)
      remote_stopped_db_service.running?.must_equal false
    end

    it 'can handle remote db start' do
      stub_psql_cmd_available?(RemoteStoppedDBFeature, true)
      stub_psql_cmd_available?(RemoteDBFeature, true)
      remote_db_service.start.must_equal [0, 'mongod (Pulp) is remote and is UP.']
      result = remote_stopped_db_service.start
      result[0].must_equal 1
      result[1].must_match 'mongod (Pulp) is remote and is DOWN'
      result[1].must_match 'Unable to connect to the remote database'
      result[1].must_match(/See the log \(.*\) for more details/)
    end

    it 'can handle remote db stop' do
      stub_psql_cmd_available?(RemoteDBFeature, true)
      stub_psql_cmd_available?(RemoteStoppedDBFeature, true)
      remote_db_service.stop.must_equal [0, 'mongod (Pulp) is remote and is UP.']
      result = remote_stopped_db_service.stop
      result[0].must_equal 0
      result[1].must_match 'mongod (Pulp) is remote and is DOWN'
      result[1].must_match 'Unable to connect to the remote database'
      result[1].must_match(/See the log \(.*\) for more details/)
    end

    it 'shows error if psql is unavailable for stop,enable and disable actions' do
      stub_psql_cmd_available?(RemoteDBFeature, false)
      stub_ping(RemoteDBFeature, false)
      message = "The psql command not found.\nMake sure system has psql utility installed."
      return_status = [0, message]
      %w[stop enable disable].each do |action|
        remote_db_service.send(action.to_sym).must_equal return_status
      end
    end

    it 'shows error with exit code 1 if psql is unavailable for start and status action' do
      stub_psql_cmd_available?(RemoteStoppedDBFeature, false)
      stub_ping(RemoteStoppedDBFeature, false)
      message = "The psql command not found.\nMake sure system has psql utility installed."
      return_status = [1, message]
      %w[start status].each do |action|
        remote_stopped_db_service.send(action.to_sym).must_equal return_status
      end
    end

    describe 'matches?' do
      let(:mongod_service) { ForemanMaintain::Utils::Service::Systemd.new('mongod', 10) }

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
