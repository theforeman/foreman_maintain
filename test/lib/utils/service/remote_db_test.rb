require 'test_helper'

module ForemanMaintain
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

  describe Utils::Service::RemoteDB do
    let(:remote_db_feature) { RemoteDBFeature.new }
    let(:remote_db_service) do
      ForemanMaintain::Utils::Service::RemoteDB.new(
        'postgresql', 10, :component => 'Pulp', :db_feature => remote_db_feature
      )
    end
    let(:remote_db_service_no_comp) do
      ForemanMaintain::Utils::Service::RemoteDB.new(
        'postgresql', 10, :db_feature => RemoteDBFeature.new
      )
    end
    let(:remote_stopped_db_service) do
      ForemanMaintain::Utils::Service::RemoteDB.new(
        'postgresql', 10, :component => 'Pulp', :db_feature => RemoteStoppedDBFeature.new
      )
    end

    it 'has component' do
      _(remote_db_service_no_comp.component).must_be_nil
      _(remote_db_service.component).must_equal 'Pulp'
    end

    it 'has db_feature' do
      _(remote_db_service.db_feature).must_equal remote_db_feature
    end

    it 'interpolates to its name' do
      _(remote_db_service_no_comp.to_s).must_equal 'postgresql'
      _(remote_db_service.to_s).must_equal 'postgresql (Pulp)'
    end

    it 'inspects itself nicely' do
      _(remote_db_service.inspect).must_equal 'RemoteDB(postgresql:Pulp [10])'
      _(remote_db_service_no_comp.inspect).must_equal 'RemoteDB(postgresql [10])'
    end

    it 'can tell the status for remote DB' do
      _(remote_db_service.status).must_equal [0, 'postgresql (Pulp) is remote and is UP.']
    end

    it 'prevents remote db from disabling' do
      result = [0, "postgresql (Pulp) is remote and is UP. It can't be disabled."]
      _(remote_db_service.disable).must_equal result
    end

    it 'prevents remote db from enabling' do
      result = [0, "postgresql (Pulp) is remote and is UP. It can't be enabled."]
      _(remote_db_service.enable).must_equal result
    end

    it 'can tell if the remote db is running' do
      _(remote_db_service.running?).must_equal true
      _(remote_stopped_db_service.running?).must_equal false
    end

    it 'can handle remote db start' do
      _(remote_db_service.start).must_equal [0, 'postgresql (Pulp) is remote and is UP.']
      result = remote_stopped_db_service.start
      _(result[0]).must_equal 1
      _(result[1]).must_match 'postgresql (Pulp) is remote and is DOWN'
      _(result[1]).must_match 'Unable to connect to the remote database'
      _(result[1]).must_match(/See the log \(.*\) for more details/)
    end

    it 'can handle remote db stop' do
      _(remote_db_service.stop).must_equal [0, 'postgresql (Pulp) is remote and is UP.']
      result = remote_stopped_db_service.stop
      _(result[0]).must_equal 0
      _(result[1]).must_match 'postgresql (Pulp) is remote and is DOWN'
      _(result[1]).must_match 'Unable to connect to the remote database'
      _(result[1]).must_match(/See the log \(.*\) for more details/)
    end

    describe 'matches?' do
      let(:postgresql_service) { ForemanMaintain::Utils::Service::Systemd.new('postgresql', 10) }

      it 'can compare by name' do
        _(remote_db_service.matches?('postgresql')).must_equal true
        _(remote_db_service.matches?('httpd')).must_equal false
      end

      it 'can compare by service' do
        _(remote_db_service.matches?(remote_db_service)).must_equal true
        _(remote_db_service.matches?(postgresql_service)).must_equal false
      end
    end
  end
end
