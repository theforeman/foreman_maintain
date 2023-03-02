
describe ForemanMaintain do
  subject { ForemanMaintain }

  describe '#package_manager' do
    before do
      subject.stubs(:`).returns('')
      subject.instance_variable_set(:@package_manager, nil)
    end

    it 'instantiates correct yum manager implementation' do
      subject.stubs(:el?).returns(true)
      subject.stubs(:el7?).returns(true)
      subject.package_manager.must_be_instance_of ForemanMaintain::PackageManager::Yum
    end

    it 'instantiates correct dnf manager implementation' do
      subject.stubs(:el?).returns(true)
      subject.stubs(:el7?).returns(false)
      subject.package_manager.must_be_instance_of ForemanMaintain::PackageManager::Dnf
    end

    it 'instantiates correct apt manager implementation' do
      subject.stubs(:el?).returns(false)
      subject.stubs(:debian?).returns(true)
      subject.package_manager.must_be_instance_of ForemanMaintain::PackageManager::Apt
    end

    it 'fail on unknown manager type' do
      subject.stubs(:el?).returns(false)
      subject.stubs(:debian?).returns(false)
      subject.stubs(:ubuntu?).returns(false)
      err = proc { subject.package_manager }.must_raise Exception
      err.message.must_equal 'No supported package manager was found'
    end
  end

  describe 'enable_maintenance_module' do
    before do
      subject.stubs(:el?).returns(true)
      subject.stubs(:el7?).returns(false)
    end

    let(:package_manager) { ForemanMaintain.package_manager }

    it 'should enable the maintenance module' do
      package_manager.expects(:module_exists?).with('satellite-maintenance:el8').returns(true)
      package_manager.expects(:module_enabled?).with('satellite-maintenance:el8').returns(false)
      package_manager.expects(:enable_module).with('satellite-maintenance:el8').returns(true)

      assert_output("\nEnabling satellite-maintenance:el8 module\n") do
        subject.enable_maintenance_module
      end
    end

    it 'should not enable the maintenance module if module does not exist' do
      package_manager.expects(:module_exists?).with('satellite-maintenance:el8').returns(false)

      assert_output('') do
        subject.enable_maintenance_module
      end
    end

    it 'should not enable the maintenance module if module is already enabled' do
      package_manager.expects(:module_exists?).with('satellite-maintenance:el8').returns(true)
      package_manager.expects(:module_enabled?).with('satellite-maintenance:el8').returns(true)

      assert_output('') do
        subject.enable_maintenance_module
      end
    end
  end
end
