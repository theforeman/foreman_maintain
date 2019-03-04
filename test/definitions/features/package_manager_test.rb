require 'test_helper'

describe Features::PackageManager do
  include DefinitionsTestHelper
  subject { Class.new(Features::PackageManager).new }

  before do
    subject.class.stubs(:command_present?).returns(false)
  end

  describe 'type' do
    it 'detects installed package manager' do
      subject.class.stubs(:command_present?).with('yum').returns(true)
      subject.type.must_equal 'yum'
    end

    it 'detects dnf package manager when dnf and yum are present' do
      subject.class.stubs(:command_present?).with('yum').returns(true)
      subject.class.stubs(:command_present?).with('dnf').returns(true)
      subject.type.must_equal 'dnf'
    end  end

  describe 'manager' do
    before do
      Features::PackageManager.any_instance.unstub(:manager)
    end

    it 'instantiates correct yum manager implementation' do
      subject.class.stubs(:command_present?).with('yum').returns(true)
      subject.manager.must_be_instance_of ForemanMaintain::PackageManager::Yum
    end

    it 'instantiates correct dnf manager implementation' do
      subject.class.stubs(:command_present?).with('yum').returns(true)
      subject.class.stubs(:command_present?).with('dnf').returns(true)
      subject.manager.must_be_instance_of ForemanMaintain::PackageManager::Dnf
    end

    it 'fail on unknown manager type' do
      err = proc { subject.manager }.must_raise Exception
      err.message.must_equal 'No supported package manager was found'
    end
  end
end
