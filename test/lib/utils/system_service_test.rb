require 'test_helper'

module ForemanMaintain
  describe '#system_service' do
    class FakeFeature; end
    let(:fake_feature) { FakeFeature.new }
    it 'can create normal system service object' do
      service = ForemanMaintain::Utils.system_service('serviced', 30)
      _(service).must_be_instance_of ForemanMaintain::Utils::Service::Systemd
      _(service.name).must_equal 'serviced'
      _(service.priority).must_equal 30
    end

    it 'creates RemoteDBService for remote postgres' do
      fake_feature.stubs(:local?).returns(false)
      service = ForemanMaintain::Utils.system_service(
        'postgresql', 30, :component => 'Foreman', :db_feature => fake_feature
      )
      _(service).must_be_instance_of ForemanMaintain::Utils::Service::RemoteDB
      _(service.name).must_equal 'postgresql'
      _(service.priority).must_equal 30
      _(service.component).must_equal 'Foreman'
      _(service.db_feature).must_equal fake_feature
    end

    it 'creates SystemService for local postgres' do
      fake_feature.stubs(:local?).returns(true)
      service = ForemanMaintain::Utils.system_service(
        'postgresql', 30, :component => 'Foreman', :db_feature => fake_feature
      )
      _(service).must_be_instance_of ForemanMaintain::Utils::Service::Systemd
      _(service.name).must_equal 'postgresql'
      _(service.priority).must_equal 30
    end

    it 'creates RemoteDBService for remote mongo' do
      fake_feature.stubs(:local?).returns(false)
      service = ForemanMaintain::Utils.system_service(
        'rh-mongodb34-mongod', 30, :db_feature => fake_feature
      )
      _(service).must_be_instance_of ForemanMaintain::Utils::Service::RemoteDB
    end

    it 'creates SystemService for local mongo' do
      fake_feature.stubs(:local?).returns(true)
      service = ForemanMaintain::Utils.system_service(
        'rh-mongodb34-mongod', 30, :db_feature => fake_feature
      )
      _(service).must_be_instance_of ForemanMaintain::Utils::Service::Systemd
    end
  end
end
