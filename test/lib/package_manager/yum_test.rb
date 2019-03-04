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

    def with_lock_config(lock_list_path)
      template = ERB.new(File.read(File.join(config_dir, 'versionlock.conf.erb')))
      Tempfile.open('test_versionlock.conf') do |tmp|
        tmp.write(template.result(binding))
        tmp.close
        yield(tmp)
      end
    end

    subject { PackageManager::Yum.new }
    let(:config_dir) { File.expand_path('test/data/package_manager/yum') }
    let(:unlocked_list_path) { File.join(config_dir, 'versionlock_unlocked.list') }
    let(:locked_list_path) { File.join(config_dir, 'versionlock_locked.list') }
    let(:locked_alt_list_path) { File.join(config_dir, 'versionlock_locked_alt.list') }
    let(:packages_to_lock) do
      [
        '0:ansiblerole-insights-client-1.6-1.el7sat.noarch',
        '0:candlepin-2.5.14-1.el7sat.noarch',
        '0:candlepin-selinux-2.5.14-1.el7sat.noarch',
        '0:tfm-runtime-5.0-3.el7sat.x86_64'
      ].map { |p| PackageManager::Yum.parse_envra(p) }
    end

    describe 'lock_versions' do
      it 'locks unlocked versions' do
        original_list = File.read(unlocked_list_path)
        Tempfile.open('lock.list') do |lock_list|
          # prepare empty lock list
          lock_list.write(original_list)
          lock_list.rewind
          # prepare lock config
          with_lock_config(lock_list.path) do |lock_conf|
            # stub yum to use our lock config
            subject.stubs(:versionlock_config_file).returns(lock_conf.path)
            subject.lock_versions(packages_to_lock)
            lock_list.rewind
            lock_list.read.must_equal File.read(locked_list_path)
          end
        end
      end

      it 'locks locked versions with new packages' do
        original_list = File.read(locked_alt_list_path)
        Tempfile.open('lock.list') do |lock_list|
          lock_list.write(original_list)
          lock_list.rewind
          with_lock_config(lock_list.path) do |lock_conf|
            subject.stubs(:versionlock_config_file).returns(lock_conf.path)
            subject.lock_versions(packages_to_lock)
            lock_list.rewind
            lock_list.read.must_equal File.read(locked_list_path)
          end
        end
      end
    end

    describe 'unlock_versions' do
      it 'unlocks locked versions' do
        original_list = File.read(locked_list_path)
        Tempfile.open('lock.list') do |lock_list|
          lock_list.write(original_list)
          lock_list.rewind
          with_lock_config(lock_list.path) do |lock_conf|
            subject.stubs(:versionlock_config_file).returns(lock_conf.path)
            subject.unlock_versions
            lock_list.rewind
            lock_list.read.must_equal File.read(unlocked_list_path)
          end
        end
      end

      it 'does nothing on unlocked versions' do
        original_list = File.read(unlocked_list_path)
        Tempfile.open('lock.list') do |lock_list|
          lock_list.write(original_list)
          lock_list.rewind
          with_lock_config(lock_list.path) do |lock_conf|
            subject.stubs(:versionlock_config_file).returns(lock_conf.path)
            subject.unlock_versions
            lock_list.rewind
            lock_list.read.must_equal original_list
          end
        end
      end
    end

    describe 'versions_locked?' do
      it 'checks if packages were locked by lock_versions' do
        with_lock_config(File.join(config_dir, 'versionlock_locked.list')) do |lock_conf|
          subject.stubs(:versionlock_config_file).returns(lock_conf.path)
          subject.versions_locked?.must_equal true
        end
      end

      it 'checks if packages were not locked by lock_versions' do
        with_lock_config(File.join(config_dir, 'versionlock_unlocked.list')) do |lock_conf|
          subject.stubs(:versionlock_config_file).returns(lock_conf.path)
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
        subject.install(%w[package1 package2])
      end

      it 'invokes yum to install package with yes enforced' do
        expect_sys_execute('yum -y install package', :via => :execute!)
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
        expect_sys_execute('yum -y update package', :via => :execute!)
        subject.update('package', :assumeyes => true)
      end

      it 'invokes yum to update all packages' do
        expect_sys_execute('yum update', :via => :execute!)
        subject.update
      end
    end

    describe 'clean_cache' do
      it 'invokes yum to clean cache' do
        expect_sys_execute('yum clean all', :via => :execute!)
        subject.clean_cache
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
