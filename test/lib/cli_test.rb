require 'test_helper'

require 'foreman_maintain/cli'

module ForemanMaintain
  describe Cli::MainCommand do
    include CliAssertions

    let :command do
      []
    end

    it 'prints help' do
      assert_cmd <<-OUTPUT.strip_heredoc, :ignore_whitespace => true
        Usage:
            foreman-maintain [OPTIONS] SUBCOMMAND [ARG] ...

        Parameters:
            SUBCOMMAND                    subcommand
            [ARG] ...                     subcommand arguments

        Subcommands:
            health                        Health related commands
            upgrade                       Upgrade related commands
            service                       Control applicable services
            backup                        Backup server
            restore                       Restore a backup
            packages                      Lock/Unlock package protection, install, update
            advanced                      Advanced tools for server maintenance
            content                       Content related commands
            maintenance-mode              Control maintenance-mode for application

        Options:
            -h, --help                    print help
      OUTPUT
    end
  end
end
