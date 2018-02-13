require 'test_helper'

describe Features::Instance do
  include DefinitionsTestHelper

  subject { Features::Instance.new }
  let(:data_dir) { File.join(File.dirname(__FILE__), '../../data') }

  describe '.product_name' do
    it 'recognizes Capsule' do
      assume_feature_absent(:foreman_server)
      assume_feature_present(:foreman_proxy)
      assume_feature_present(:downstream)
      subject.product_name.must_equal 'Capsule'
    end

    it 'recognizes Foreman Proxy' do
      assume_feature_absent(:foreman_server)
      assume_feature_absent(:downstream)
      assume_feature_present(:foreman_proxy)
      subject.product_name.must_equal 'Foreman Proxy'
    end

    it 'recognizes Katello' do
      assume_feature_present(:foreman_server)
      assume_feature_present(:foreman_proxy)
      assume_feature_present(:katello)
      assume_feature_absent(:downstream)
      subject.product_name.must_equal 'Katello'
    end

    it 'recognizes Satellite' do
      assume_feature_present(:foreman_server)
      assume_feature_present(:foreman_proxy)
      assume_feature_present(:katello)
      assume_feature_present(:downstream)
      subject.product_name.must_equal 'Satellite'
    end

    it 'recognizes Foreman' do
      assume_feature_present(:foreman_server)
      assume_feature_present(:foreman_proxy)
      assume_feature_absent(:katello)
      assume_feature_absent(:downstream)
      subject.product_name.must_equal 'Foreman'
    end
  end

  describe '.database_local?' do
    %w[candlepin_database foreman_database mongo].each do |feature|
      describe feature do
        it "is true when the #{feature} is present and local" do
          assume_feature_present(feature.to_sym) do |db|
            db.any_instance.stubs(:local?).returns(true)
            if feature == 'mongo'
              db.any_instance.stubs(:config_file).returns("#{data_dir}/mongo/default_server.conf")
            end
          end
          subject.database_local?(feature.to_sym).must_equal(true)
        end

        it "is false when the #{feature} is not present" do
          assume_feature_absent(feature.to_sym)
          subject.database_local?(feature.to_sym).must_equal(false)
        end

        it "is false when the #{feature} is present and remote" do
          assume_feature_present(feature.to_sym) do |db|
            db.any_instance.stubs(:local?).returns(false)
            if feature == 'mongo'
              db.any_instance.stubs(:config_file).returns("#{data_dir}/mongo/default_server.conf")
            end
          end
          subject.database_local?(feature.to_sym).must_equal(false)
        end
      end
    end
  end
end
