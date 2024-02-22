describe ForemanMaintain do
  subject { ForemanMaintain }

  describe '#package_manager' do
    before do
      subject.stubs(:`).returns('')
      subject.instance_variable_set(:@package_manager, nil)
    end

    it 'instantiates correct dnf manager implementation' do
      subject.stubs(:el?).returns(true)
      _(subject.package_manager).must_be_instance_of ForemanMaintain::PackageManager::Dnf
    end

    it 'instantiates correct apt manager implementation' do
      subject.stubs(:el?).returns(false)
      subject.stubs(:debian?).returns(true)
      _(subject.package_manager).must_be_instance_of ForemanMaintain::PackageManager::Apt
    end

    it 'fail on unknown manager type' do
      subject.stubs(:el?).returns(false)
      subject.stubs(:debian?).returns(false)
      subject.stubs(:ubuntu?).returns(false)
      assert_raises(RuntimeError, 'No supported package manager was found') do
        subject.package_manager
      end
    end
  end

  describe 'enable_maintenance_module' do
    before do
      subject.stubs(:el8?).returns(true)
      subject.stubs(:el?).returns(true)
    end

    let(:package_manager) { ForemanMaintain::PackageManager::Dnf }

    it 'should enable the maintenance module' do
      package_manager.any_instance.stubs(:module_exists?).returns(true)
      package_manager.any_instance.stubs(:module_enabled?).returns(false)

      package_manager.any_instance.expects(:enable_module).with('satellite-maintenance:el8').once

      assert_output("\nEnabling satellite-maintenance:el8 module\n") do
        subject.enable_maintenance_module
      end
    end

    it 'should not enable the maintenance module if module does not exist' do
      package_manager.any_instance.stubs(:module_exists?).returns(false)

      package_manager.any_instance.expects(:enable_module).with('satellite-maintenance:el8').never

      assert_output('') do
        subject.enable_maintenance_module
      end
    end

    it 'should not enable the maintenance module if module is already enabled' do
      package_manager.any_instance.stubs(:module_exists?).returns(true)
      package_manager.any_instance.stubs(:module_enabled?).returns(true)

      package_manager.any_instance.expects(:enable_module).with('satellite-maintenance:el8').never

      assert_output('') do
        subject.enable_maintenance_module
      end
    end

    it 'should not enable the maintenance module on el9' do
      subject.stubs(:el8?).returns(false)
      package_manager.any_instance.stubs(:module_exists?).returns(false)
      package_manager.any_instance.stubs(:module_enabled?).returns(false)

      package_manager.any_instance.expects(:enable_module).with('satellite-maintenance:el8').never

      assert_output('') do
        subject.enable_maintenance_module
      end
    end
  end

  describe '#main_package_name' do
    it 'should return rubygem-foreman_maintain on EL systems' do
      subject.stubs(:el?).returns(true)

      _(subject.main_package_name).must_equal 'rubygem-foreman_maintain'
    end

    it 'should return ruby-foreman-maintain on Debian systems' do
      subject.stubs(:el?).returns(false)

      _(subject.main_package_name).must_equal 'ruby-foreman-maintain'
    end
  end
end
