require 'test_helper'

module ForemanMaintain
  describe Utils::Distros::Debian do
    let :debian do
      Utils::Distros::Debian.new
    end

    let :expected_error_msg do
      'Manifest file not found. Please follow upgrade instructions ' \
      'https://www.theforeman.org/manuals/1.15/index.html#3.6Upgrade'
    end

    describe '.setup_repositories' do
      it 'raises error if source_list_file not found' do
        debian.stubs(:source_list_file)
        debian.stubs(:upgrade_version).returns('1.15')

        failure = assert_raises(Error::Fail) { debian.setup_repositories }
        assert_equal(expected_error_msg, failure.message)
      end

      it 'successfully updates source_list_file and perform_upgrade' do
        debian.stubs(:source_list_file).returns(true)
        debian.expects(:update_source_list_file)
        debian.expects(:upgrade_foreman_package)

        debian.setup_repositories
      end
    end
  end
end
