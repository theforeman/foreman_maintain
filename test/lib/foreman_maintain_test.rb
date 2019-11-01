describe ForemanMaintain do
  subject { ForemanMaintain }

  describe '#package_manager' do
    before do
      subject.stubs(:`).returns('')
      subject.instance_variable_set(:@package_manager, nil)
    end

    it 'instantiates correct yum manager implementation' do
      subject.stubs(:`).with('command -v yum').returns('/bin/yum')
      subject.package_manager.must_be_instance_of ForemanMaintain::PackageManager::Yum
    end

    it 'instantiates correct dnf manager implementation' do
      subject.stubs(:`).with('command -v yum').returns('/bin/yum')
      subject.stubs(:`).with('command -v dnf').returns('/bin/dnf')
      subject.package_manager.must_be_instance_of ForemanMaintain::PackageManager::Dnf
    end

    it 'fail on unknown manager type' do
      err = proc { subject.package_manager }.must_raise Exception
      err.message.must_equal 'No supported package manager was found'
    end
  end
end
