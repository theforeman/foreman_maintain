require 'test_helper'

require 'foreman_maintain/cli'

module ForemanMaintain
  describe Cli::MainCommand do
    include CliAssertions

    let :command do
      []
    end

    it 'prints help' do
      assert_cmd <<-OUTPUT.strip_heredoc
        Usage:
            foreman-maintain [OPTIONS] SUBCOMMAND [ARG] ...

        Parameters:
            SUBCOMMAND                    subcommand
            [ARG] ...                     subcommand arguments

        Subcommands:
            health                        Health related commands
            upgrade                       Upgrade related commands
            backup                        Backup server
            advanced                      Advanced tools for server maintenance
            service                       Control applicable services

        Options:
            -h, --help                    print help
      OUTPUT
    end
  end
end
