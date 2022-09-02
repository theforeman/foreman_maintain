
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
      err = proc { subject.package_manager }.must_raise RuntimeError
      err.message.must_equal 'No supported package manager was found'
    end
  end
end
