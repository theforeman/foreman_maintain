require 'test_helper'
require 'tempfile'
require 'foreman_maintain/package_manager'

module ForemanMaintain
  describe PackageManager::Yum do
    def expect_sys_execute(command, via: :execute,
                           execute_options: { :interactive => true }, response: 'OK')
      ForemanMaintain::Utils::SystemHelpers.expects(via).
        with(command, execute_options).returns(response)
    end

    def with_lock_config(protector_enabled: false)
      template = ERB.new(File.read(File.join(config_dir, 'foreman-protector.conf.erb')))
      Tempfile.open('test_foreman-protector.conf') do |tmp|
        tmp.write(template.result(binding))
        tmp.rewind
        yield(tmp)
      end
    end

    subject { PackageManager::Yum.new }
    let(:config_dir) { File.expand_path('test/data/package_manager/yum') }

    describe 'lock_versions' do
      it 'locks unlocked versions' do
        with_lock_config(:protector_enabled => false) do |lock_conf|
          subject.stubs(:protector_config_file).returns(lock_conf.path)
          lock_conf.rewind
          subject.lock_versions
          lock_conf.rewind
          subject.versions_locked?.must_equal true
        end
      end

      it 'does nothing on locked versions' do
        with_lock_config(:protector_enabled => true) do |lock_conf|
          subject.stubs(:protector_config_file).returns(lock_conf.path)
          lock_conf.rewind
          subject.lock_versions
          lock_conf.rewind
          subject.versions_locked?.must_equal true
        end
      end
    end

    describe 'unlock_versions' do
      it 'unlocks locked versions' do
        with_lock_config(:protector_enabled => true) do |lock_conf|
          subject.stubs(:protector_config_file).returns(lock_conf.path)
          lock_conf.rewind
          subject.unlock_versions
          lock_conf.rewind
          subject.versions_locked?.must_equal false
        end
      end

      it 'does nothing on unlocked versions' do
        with_lock_config(:protector_enabled => false) do |lock_conf|
          subject.stubs(:protector_config_file).returns(lock_conf.path)
          lock_conf.rewind
          subject.unlock_versions
          lock_conf.rewind
          subject.versions_locked?.must_equal false
        end
      end
    end

    describe 'versions_locked?' do
      it 'checks if packages were locked by lock_versions' do
        with_lock_config(:protector_enabled => true) do |lock_conf|
          subject.stubs(:protector_config_file).returns(lock_conf.path)
          subject.versions_locked?.must_equal true
        end
      end

      it 'checks if packages were not locked by lock_versions' do
        with_lock_config(:protector_enabled => false) do |lock_conf|
          subject.stubs(:protector_config_file).returns(lock_conf.path)
          lock_conf.rewind
          subject.versions_locked?.must_equal false
        end
      end
    end

    describe 'install' do
      it 'invokes yum to install single package' do
        expect_sys_execute('yum install package', :via => :execute!)
        subject.install('package')
      end

      it 'invokes yum to install list of packages' do
        expect_sys_execute('yum install package1 package2', :via => :execute!)
        subject.install(%w[package1 package2], :assumeyes => false)
      end

      it 'invokes yum to install package with yes enforced' do
        expect_sys_execute('yum -y install package', :via => :execute!,
                                                     :execute_options => { :interactive => false })
        subject.install('package', :assumeyes => true)
      end
    end

    describe 'update' do
      it 'invokes yum to update single package' do
        expect_sys_execute('yum update package', :via => :execute!)
        subject.update('package')
      end

      it 'invokes yum to update list of packages' do
        expect_sys_execute('yum update package1 package2', :via => :execute!)
        subject.update(%w[package1 package2])
      end

      it 'invokes yum to update package with yes enforced' do
        expect_sys_execute('yum -y update package', :via => :execute!,
                                                    :execute_options => { :interactive => false })
        subject.update('package', :assumeyes => true)
      end

      it 'invokes yum to update all packages' do
        expect_sys_execute('yum update', :via => :execute!)
        subject.update
      end
    end

    describe 'clean_cache' do
      it 'invokes yum to clean cache' do
        expect_sys_execute('yum -y clean all', :via => :execute!,
                                               :execute_options => { :interactive => false })
        subject.clean_cache(:assumeyes => true)
      end
    end

    describe 'installed?' do
      it 'returns true if all packages listed are installed' do
        expect_sys_execute("rpm -q 'package1' 'package2'",
                           :via => :execute?, :execute_options => nil, :response => true)
        subject.installed?(%w[package1 package2]).must_equal true
      end

      it 'returns false if any of the packages is not installed' do
        expect_sys_execute("rpm -q 'missing' 'package'",
                           :via => :execute?, :execute_options => nil, :response => false)
        subject.installed?(%w[missing package]).must_equal false
      end

      it 'handles single package too' do
        expect_sys_execute("rpm -q 'package'", :via => :execute?, :execute_options => nil,
                                               :response => true)
        subject.installed?('package').must_equal true
      end
    end

    describe 'find_installed_package' do
      it 'invokes rpm to lookup the package and returns the pacakge' do
        expect_sys_execute("rpm -q 'package'",
                           :via => :execute_with_status,
                           :execute_options => nil,
                           :response => [0, 'package-3.4.3-161.el7.noarch'])
        subject.find_installed_package('package').must_equal 'package-3.4.3-161.el7.noarch'
      end

      it 'invokes rpm to lookup the package and returns nil if not found' do
        expect_sys_execute("rpm -q 'package'",
                           :via => :execute_with_status,
                           :execute_options => nil,
                           :response => [1, 'package package is not insalled'])
        assert_nil subject.find_installed_package('package')
      end
    end
  end
end
