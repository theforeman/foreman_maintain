require 'test_helper'

require 'foreman_maintain/cli'

include CliAssertions
module ForemanMaintain
  describe Cli::UpgradeCommand do
    include CliAssertions
    before do
      ForemanMaintain.detector.refresh
    end
    let :command do
      %w[upgrade]
    end

    it 'prints help' do
      assert_cmd <<-OUTPUT.strip_heredoc
        Usage:
            foreman-maintain upgrade [OPTIONS] SUBCOMMAND [ARG] ...

        Parameters:
            SUBCOMMAND                    subcommand
            [ARG] ...                     subcommand arguments

        Subcommands:
            list-versions                 List versions this system is upgradable to
            check                         Run pre-upgrade checks for upgrading to specified version
            advanced                      Advanced commands: use with caution
            run                           Run full upgrade to a specified version

        Options:
            -h, --help                    print help
      OUTPUT
    end

    describe 'list-versions' do
      let :command do
        %w[upgrade list-versions]
      end
      it 'lists the available versions' do
        assert_cmd <<-OUTPUT.strip_heredoc
          1.15
        OUTPUT
      end
    end

    describe 'check' do
      let :command do
        %w[upgrade check]
      end

      it 'runs the upgrade checks for version' do
        UpgradeRunner.any_instance.expects(:run_phase).with(:pre_upgrade_checks)
        run_cmd(['1.15'])
      end
    end

    describe 'advanced run' do
      let :command do
        %w[upgrade advanced run]
      end

      it 'runs the specific phase' do
        UpgradeRunner.any_instance.expects(:run_phase).with(:pre_migrations)
        run_cmd(['--phase=pre_migrations', '1.15'])
      end
    end

    describe 'run' do
      let :command do
        %w[upgrade run]
      end

      it 'runs the full upgrade for version' do
        UpgradeRunner.any_instance.expects(:run)
        run_cmd(['1.15'])
      end
    end
  end
end
