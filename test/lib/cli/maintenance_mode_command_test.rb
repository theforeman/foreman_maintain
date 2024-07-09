require 'test_helper'

require 'foreman_maintain/cli'

module ForemanMaintain
  include CliAssertions
  describe Cli::MaintenanceModeCommand do
    include CliAssertions
    let :command do
      %w[maintenance-mode]
    end

    it 'prints help' do
      assert_cmd <<~OUTPUT, :ignore_whitespace => true
        Usage:
            foreman-maintain maintenance-mode [OPTIONS] SUBCOMMAND [ARG] ...

        Parameters:
            SUBCOMMAND                    subcommand
            [ARG] ...                     subcommand arguments

        Subcommands:
            start                         Start maintenance-mode
            stop                          Stop maintenance-mode
            status                        Get maintenance-mode status
            is-enabled                    Get maintenance-mode status code

        Options:
            -h, --help                    print help
      OUTPUT
    end
  end
end
