require 'test_helper'
require 'tempfile'
require 'foreman_maintain/package_manager'

module ForemanMaintain
  describe PackageManager::Apt do
    subject { PackageManager::Apt.new }

    describe 'reboot_required?' do
      it 'returns 1 if a reboot is required' do
        File.expects(:exist?).with('/var/run/reboot-required').returns(true)
        assert_equal subject.reboot_required?, [1, '']
      end

      it 'returns 0 if a reboot is not required' do
        File.expects(:exist?).with('/var/run/reboot-required').returns(false)
        assert_equal subject.reboot_required?, [0, '']
      end
    end
  end
end
