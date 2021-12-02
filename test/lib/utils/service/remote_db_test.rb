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
        'pulpcore_database', 10, :component => 'Pulp', :db_feature => remote_db_feature
      )
    end
    let(:remote_db_service_no_comp) do
      ForemanMaintain::Utils::Service::RemoteDB.new(
        'pulpcore_database', 10, :db_feature => RemoteDBFeature.new
      )
    end
    let(:remote_stopped_db_service) do
      ForemanMaintain::Utils::Service::RemoteDB.new(
        'pulpcore_database', 10, :component => 'Pulp', :db_feature => RemoteStoppedDBFeature.new
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
      remote_db_service_no_comp.to_s.must_equal 'pulpcore_database'
      remote_db_service.to_s.must_equal 'pulpcore_database (Pulp)'
    end

    it 'inspects itself nicely' do
      remote_db_service.inspect.must_equal 'RemoteDB(pulpcore_database:Pulp [10])'
      remote_db_service_no_comp.inspect.must_equal 'RemoteDB(pulpcore_database [10])'
    end

    it 'can tell the status for remote DB' do
      remote_db_service.status.must_equal [0, 'pulpcore_database (Pulp) is remote and is UP.']
    end

    it 'prevents remote db from disabling' do
      result = [0, "pulpcore_database (Pulp) is remote and is UP. It can't be disabled."]
      remote_db_service.disable.must_equal result
    end

    it 'prevents remote db from enabling' do
      result = [0, "pulpcore_database (Pulp) is remote and is UP. It can't be enabled."]
      remote_db_service.enable.must_equal result
    end

    it 'can tell if the remote db is running' do
      remote_db_service.running?.must_equal true
      remote_stopped_db_service.running?.must_equal false
    end

    it 'can handle remote db start' do
      remote_db_service.start.must_equal [0, 'pulpcore_database (Pulp) is remote and is UP.']
      result = remote_stopped_db_service.start
      result[0].must_equal 1
      result[1].must_match 'pulpcore_database (Pulp) is remote and is DOWN'
      result[1].must_match 'Unable to connect to the remote database'
      result[1].must_match(/See the log \(.*\) for more details/)
    end

    it 'can handle remote db stop' do
      remote_db_service.stop.must_equal [0, 'pulpcore_database (Pulp) is remote and is UP.']
      result = remote_stopped_db_service.stop
      result[0].must_equal 0
      result[1].must_match 'pulpcore_database (Pulp) is remote and is DOWN'
      result[1].must_match 'Unable to connect to the remote database'
      result[1].must_match(/See the log \(.*\) for more details/)
    end

    describe 'matches?' do
      let(:pulpcore_database) { ForemanMaintain::Utils::Service::Systemd.new('pulpcore_database', 10) }

      it 'can compare by name' do
        remote_db_service.matches?('pulpcore_database').must_equal true
        remote_db_service.matches?('httpd').must_equal false
      end

      it 'can compare by service' do
        remote_db_service.matches?(remote_db_service).must_equal true
        remote_db_service.matches?(pulpcore_database).must_equal false
      end
    end
  end
end
