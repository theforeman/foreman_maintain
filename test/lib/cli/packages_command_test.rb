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
            lock                          Prevent Foreman-related packages from automatic update
            unlock                        Enable Foreman-related packages for automatic update
            status                        Check if Foreman-related packages are protected against update
            is-locked                     Check if update of Foreman-related packages is allowed

        Options:
            -h, --help                    print help
      OUTPUT
    end
  end
end
