require 'test_helper'

module ForemanMaintain
  describe '#system_service' do
    class FakeFeature; end
    let(:fake_feature) { FakeFeature.new }
    it 'can create normal system service object' do
      service = ForemanMaintain::Utils.system_service('serviced', 30)
      service.must_be_instance_of ForemanMaintain::Utils::Service::Systemd
      service.name.must_equal 'serviced'
      service.priority.must_equal 30
    end

    it 'creates RemoteDBService for remote postgres' do
      fake_feature.stubs(:local?).returns(false)
      service = ForemanMaintain::Utils.system_service(
        'postgresql', 30, :component => 'Foreman', :db_feature => fake_feature
      )
      service.must_be_instance_of ForemanMaintain::Utils::Service::RemoteDB
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
      service.must_be_instance_of ForemanMaintain::Utils::Service::Systemd
      service.name.must_equal 'postgresql'
      service.priority.must_equal 30
    end
  end
end
