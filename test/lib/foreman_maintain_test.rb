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
