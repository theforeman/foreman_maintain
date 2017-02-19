require 'test_helper'

require 'foreman_maintain/cli'

include CliAssertions
module ForemanMaintain
  describe Cli::MainCommand do
    let :command do
      []
    end

    it 'prints help' do
      assert_cmd <<OUTPUT
Usage:
    foreman-maintain [OPTIONS] SUBCOMMAND [ARG] ...

Parameters:
    SUBCOMMAND                    subcommand
    [ARG] ...                     subcommand arguments

Subcommands:
    health                        Health related commands
    upgrade                       Upgrade related commands

Options:
    -h, --help                    print help
OUTPUT
    end
  end
end
