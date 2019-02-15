require 'test_helper'

describe Features::Service do
  include DefinitionsTestHelper

  class RemoteDBFeature
    def local?
      false
    end
  end

  class LocalDBFeature
    def local?
      true
    end
  end

  def service_names_match?(filtered_services, services_to_compare)
    filtered_services.map(&:name).must_equal services_to_compare.map(&:name)
  end

  def includes_available_feature_services?(filtered_services, feature_services)
    matching_services = feature_services.select do |service|
      filtered_services.any? { |obj| service.matches?(obj) }
    end
    assert matching_services.length, feature_services.length
  end

  let(:httpd) { existing_system_service('httpd', 30) }
  let(:local_foreman_db) do
    existing_system_service('postgresql', 20,
                            :component => 'Foreman', :db_feature => LocalDBFeature.new)
  end
  let(:local_candlepin_db) do
    existing_system_service('postgresql', 10,
                            :component => 'Candlepin', :db_feature => LocalDBFeature.new)
  end
  let(:remote_foreman_db) do
    existing_system_service('postgresql', 20,
                            :component => 'Foreman', :db_feature => RemoteDBFeature.new)
  end
  let(:remote_candlepin_db) do
    existing_system_service('postgresql', 10,
                            :component => 'Candlepin', :db_feature => RemoteDBFeature.new)
  end
  let(:missing) { missing_system_service('missing', 30) }

  let(:crond) { existing_system_service('crond', 30) }

  class TestFeature < ForemanMaintain::Feature
    def initialize(*services)
      @services = services
    end

    attr_reader :services
  end

  subject { Features::Service.new }

  describe 'existing_services' do
    it 'returns list of sorted existing services (local)' do
      ForemanMaintain.stubs(:available_features).returns(
        [
          TestFeature.new(httpd, local_foreman_db),
          TestFeature.new(httpd, local_candlepin_db),
          TestFeature.new(missing),
          TestFeature.new
        ]
      )
      subject.existing_services.must_equal [local_candlepin_db, httpd]
    end

    it 'returns list of sorted existing services (remote)' do
      ForemanMaintain.stubs(:available_features).returns(
        [
          TestFeature.new(httpd, remote_foreman_db),
          TestFeature.new(httpd, remote_candlepin_db),
          TestFeature.new(missing),
          TestFeature.new
        ]
      )
      subject.existing_services.must_equal [remote_candlepin_db, remote_foreman_db, httpd]
    end
  end

  describe 'filtered_services' do
    before do
      ForemanMaintain.stubs(:available_features).returns(
        [
          TestFeature.new(httpd, remote_foreman_db),
          TestFeature.new(httpd, remote_candlepin_db)
        ]
      )
    end

    it 'returns the same set without any filters' do
      subject.filtered_services({}).must_equal [remote_candlepin_db, remote_foreman_db, httpd]
    end

    it 'applies the only filters which includes ungistered services as well' do
      filtered_service_list = subject.filtered_services(:only => %w[httpd crond])

      includes_available_feature_services?(filtered_service_list, [httpd])
      service_names_match?(filtered_service_list, [httpd, crond])
    end

    it 'the :only filters all services regardless on component' do
      remote_dbs = [remote_candlepin_db, remote_foreman_db]

      subject.filtered_services(:only => ['postgresql']).must_equal remote_dbs
    end

    it 'the :only accepts also list of SystemServices and filter by component' do
      subject.filtered_services(:only => [remote_candlepin_db]).must_equal [remote_candlepin_db]
    end

    it 'applies the exclude filters' do
      subject.filtered_services(:exclude => ['postgresql']).must_equal [httpd]
    end

    it 'applies the include filters' do
      filtered_service_list = subject.filtered_services(:include => ['crond'])
      feature_services = [remote_candlepin_db, remote_foreman_db, httpd]

      includes_available_feature_services?(filtered_service_list, feature_services)
      service_names_match?(filtered_service_list, feature_services.push(crond))
    end

    it 'the :include accepts also list of SystemServices' do
      filtered_service_list = subject.filtered_services(:include => [httpd])

      assert filtered_service_list.include?(httpd)
    end

    it 'on adding non-exist service into :include raise exception' do
      err = assert_raises RuntimeError do
        subject.filtered_services(:include => [missing])
      end
      assert_match "No service found matching your parameter '#{missing.name}'", err.message
    end
  end
end
