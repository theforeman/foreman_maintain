require 'test_helper'

require 'foreman_maintain/cli'

module ForemanMaintain
  include CliAssertions
  describe Cli::PackagesCommand do
    include CliAssertions
    let :command do
      %w[packages]
    end

    it 'prints help' do
      assert_cmd <<-OUTPUT.strip_heredoc, :ignore_whitespace => true
        Usage:
            foreman-maintain packages [OPTIONS] SUBCOMMAND [ARG] ...

        Parameters:
            SUBCOMMAND                    subcommand
            [ARG] ...                     subcommand arguments

        Subcommands:
            lock                          Prevent packages from automatic update
            unlock                        Enable packages for automatic update
            status                        Check if packages are protected against update
            install                       Install packages in an unlocked session
            update                        Update packages in an unlocked session
            is-locked                     Check if update of packages is allowed

        Options:
            -h, --help                    print help
      OUTPUT
    end
  end
end
