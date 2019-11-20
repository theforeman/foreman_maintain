require 'test_helper'

describe Features::Instance do
  include DefinitionsTestHelper

  subject { Features::Instance.new }
  let(:data_dir) { File.join(File.dirname(__FILE__), '../../data') }

  describe '.product_name' do
    it 'recognizes Capsule' do
      assume_feature_absent(:foreman_server)
      assume_feature_present(:foreman_proxy)
      assume_feature_present(:capsule)
      assume_feature_absent(:satellite)
      subject.product_name.must_equal 'Capsule'
    end

    it 'recognizes Foreman Proxy' do
      assume_feature_absent(:foreman_server)
      assume_feature_present(:foreman_proxy)
      assume_feature_absent(:capsule)
      subject.product_name.must_equal 'Foreman Proxy'
    end

    it 'recognizes Katello' do
      assume_feature_present(:foreman_server)
      assume_feature_present(:foreman_proxy)
      assume_feature_present(:katello)
      assume_feature_absent(:satellite)
      subject.product_name.must_equal 'Katello'
    end

    it 'recognizes Satellite' do
      assume_feature_present(:foreman_server)
      assume_feature_present(:foreman_proxy)
      assume_feature_present(:katello)
      assume_feature_present(:satellite)
      subject.product_name.must_equal 'Satellite'
    end

    it 'recognizes Foreman' do
      assume_feature_present(:foreman_server)
      assume_feature_present(:foreman_proxy)
      assume_feature_absent(:katello)
      assume_feature_absent(:satellite)
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

  describe '.database_remote?' do
    %w[candlepin_database foreman_database mongo].each do |feature|
      describe feature do
        it "is false when the #{feature} is present and local" do
          assume_feature_present(feature.to_sym) do |db|
            db.any_instance.stubs(:local?).returns(true)
            if feature == 'mongo'
              db.any_instance.stubs(:config_file).returns("#{data_dir}/mongo/default_server.conf")
            end
          end
          subject.database_remote?(feature.to_sym).must_equal(false)
        end

        it "is false when the #{feature} is not present" do
          assume_feature_absent(feature.to_sym)
          subject.database_remote?(feature.to_sym).must_equal(false)
        end

        it "is true when the #{feature} is present and remote" do
          assume_feature_present(feature.to_sym) do |db|
            db.any_instance.stubs(:local?).returns(false)
            if feature == 'mongo'
              db.any_instance.stubs(:config_file).returns("#{data_dir}/mongo/default_server.conf")
            end
          end
          subject.database_remote?(feature.to_sym).must_equal(true)
        end
      end
    end
  end

  describe '.ping' do
    let(:conn_error_msg) { 'Connection refused - connect(2)' }

    context 'katello' do
      let(:existing_httpd) { existing_system_service('httpd', 10) }
      let(:existing_mongod) { existing_system_service('mongod', 5) }
      let(:missing_mongod) { missing_system_service('mongo38d', 5) }
      let(:success_response_body) do
        {
          'status' => 'ok',
          'services' => {
            'pulp' => { 'status' => 'ok', 'duration_ms' => '44' },
            'candlepin' => { 'status' => 'ok', 'duration_ms' => '15' }
          }
        }
      end
      let(:failing_response_body) do
        {
          'status' => 'ok',
          'services' => {
            'pulp' => { 'status' => 'FAIL', 'duration_ms' => '44' },
            'candlepin' => { 'status' => 'ok', 'duration_ms' => '15' }
          }
        }
      end
      let(:connection) { mock('connection') }

      before do
        assume_feature_present(:katello) do |feature_class|
          feature_class.any_instance.stubs(:current_version => version('3.2.0'))
        end
      end

      it 'fails when server is down' do
        connection.expects(:get).with('/katello/api/ping').raises conn_error_msg
        subject.stubs(:server_connection).returns(connection)

        ping = subject.ping
        ping.success?.must_equal false
        ping.message.must_equal "Couldn't connect to the server: #{conn_error_msg}"
        ping.data[:failing_services].must_be_nil
      end

      it 'succeeds when all the components are okay' do
        connection.expects(:get).with('/katello/api/ping').
          returns(mock_net_http_response('200', success_response_body))
        subject.stubs(:server_connection).returns(connection)

        ping = subject.ping
        ping.success?.must_equal true
        ping.message.must_equal 'Success'
        ping.data[:failing_services].must_be_nil
      end

      it 'fails when some of the components fail' do
        assume_feature_present(:pulp2) do |feature_class|
          feature_class.any_instance.stubs(:services).returns(existing_httpd)
        end
        assume_feature_present(:mongo) do |feature_class|
          feature_class.any_instance.stubs(:services).returns([existing_mongod, missing_mongod])
          server_conf = "#{data_dir}/mongo/default_server.conf"
          feature_class.any_instance.stubs(:config_file).returns(server_conf)
        end
        connection.expects(:get).with('/katello/api/ping').
          returns(mock_net_http_response('200', failing_response_body))
        subject.stubs(:server_connection).returns(connection)

        ping = subject.ping
        ping.success?.must_equal false
        ping.message.must_equal 'Some components are failing: pulp'
        ping.data[:failing_services].must_equal [existing_httpd, existing_mongod]
      end
    end

    context 'proxy' do
      before do
        assume_feature_absent(:katello)
        assume_feature_absent(:foreman_server)
      end

      it 'fails when proxy is down' do
        assume_feature_present(:foreman_proxy) do |feature_class|
          feature_class.any_instance.stubs(:features).raises conn_error_msg
        end

        ping = subject.ping
        ping.success?.must_equal false
        ping.message.must_equal "Couldn't connect to the proxy: #{conn_error_msg}"
        ping.data[:failing_services].must_be_nil
      end

      it 'succeeds when proxy responds' do
        assume_feature_present(:foreman_proxy) do |feature_class|
          feature_class.any_instance.stubs(:features).returns(%w[dhcp dns])
        end

        ping = subject.ping
        ping.success?.must_equal true
        ping.message.must_equal 'Success'
        ping.data[:failing_services].must_be_nil
      end
    end

    context 'foreman' do
      let(:connection) { mock('connection') }

      before do
        assume_feature_absent(:katello)
        assume_feature_present(:foreman_server)
      end

      it 'fails when server is down' do
        connection.expects(:get).with('/apidoc/apipie_checksum').raises conn_error_msg
        subject.stubs(:server_connection).returns(connection)

        ping = subject.ping
        ping.success?.must_equal false
        ping.message.must_equal "Couldn't connect to the server: #{conn_error_msg}"
        ping.data[:failing_services].must_be_nil
      end

      it 'succeeds when all the components are okay' do
        connection.expects(:get).with('/apidoc/apipie_checksum').
          returns(mock_net_http_response('200', 'checksum' => 1234))
        subject.stubs(:server_connection).returns(connection)

        ping = subject.ping
        ping.success?.must_equal true
        ping.message.must_equal 'Success'
        ping.data[:failing_services].must_be_nil
      end
    end
  end
end
