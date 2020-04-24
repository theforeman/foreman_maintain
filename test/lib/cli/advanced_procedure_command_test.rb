require 'test_helper'

require 'foreman_maintain/cli'

module ForemanMaintain
  include CliAssertions
  describe 'Advanced::Procedure' do
    include CliAssertions

    before do
      ForemanMaintain.detector.refresh
    end

    let :command do
      %w[advanced]
    end

    it 'prints procedure' do
      assert_cmd <<-OUTPUT.strip_heredoc, :ignore_whitespace => true
        Usage:
            foreman-maintain advanced [OPTIONS] SUBCOMMAND [ARG] ...

        Parameters:
            SUBCOMMAND                    subcommand
            [ARG] ...                     subcommand arguments

        Subcommands:
            procedure                     Run maintain procedures manually
            prebuild-bash-completion      Prepare map of options and subcommands for Bash completion

        Options:
            -h, --help                    print help
      OUTPUT
    end

    describe 'advanced procedure' do
      let :command do
        %w[advanced procedure]
      end

      it 'prints: run and by-tag subcommands' do
        assert_cmd <<-OUTPUT.strip_heredoc, :ignore_whitespace => true
          Usage:
              foreman-maintain advanced procedure [OPTIONS] SUBCOMMAND [ARG] ...

          Parameters:
              SUBCOMMAND                    subcommand
              [ARG] ...                     subcommand arguments

          Subcommands:
              run                           Run maintain procedures manually
              by-tag                        Run maintain procedures in bulks

          Options:
              -h, --help                    print help
        OUTPUT
      end
    end

    describe 'advanced procedure by-tag' do
      let :command do
        %w[advanced procedure by-tag]
      end

      it 'prints: available subcommands for by-tag' do
        assert_cmd <<-OUTPUT.strip_heredoc, :ignore_whitespace => true
          Usage:
              foreman-maintain advanced procedure by-tag [OPTIONS] SUBCOMMAND [ARG] ...

          Parameters:
              SUBCOMMAND                    subcommand
              [ARG] ...                     subcommand arguments

          Subcommands:
              fallacious                    Run procedures tagged #fallacious: dummy_procedure_fail
              migrations                    Run procedures tagged #migrations: upgrade_migration
              post-migrations               Run procedures tagged #post_migrations: upgrade_post_migration
              pre-migrations                Run procedures tagged #pre_migrations: stop_service, upgrade_pre_migration
              release                       Run procedures tagged #release: delete_articles_one_year_old
              restart                       Run procedures tagged #restart: present_service_restart
              start                         Run procedures tagged #start: present_service_start

          Options:
              -h, --help                    print help
        OUTPUT
      end
    end

    describe 'advanced procedure run' do
      let :command do
        %w[advanced procedure run]
      end

      it 'prints: available subcommands for run' do
        assert_cmd <<-OUTPUT.strip_heredoc, :ignore_whitespace => true
          Usage:
              foreman-maintain advanced procedure run [OPTIONS] SUBCOMMAND [ARG] ...

          Parameters:
              SUBCOMMAND                    subcommand
              [ARG] ...                     subcommand arguments

          Subcommands:
              delete-articles-one-year-old  Delete all articles created 1 year ago
              delete-articles-with-zero-comments Delete all articles with zero comments
              dummy-procedure-fail          Procedure that ends up with fail
              present-service-restart       Restart present service
              present-service-start         Start the present service
              run-once                      Procedures::RunOnce
              setup                         Setup
              stop-service                  Stop the running service
              upgrade-migration             Procedures::Upgrade::Migration
              upgrade-post-migration        Procedures::Upgrade::PostMigration
              upgrade-pre-migration         Procedures::Upgrade::PreMigration
              with-param                    Procedures::WithParam

          Options:
              -h, --help                    print help
        OUTPUT
      end
    end

    describe 'run procedure' do
      let :command do
        %w[advanced procedure run dummy-procedure-fail]
      end

      it 'exits with 1 if failed' do
        Scenario.any_instance.expects(:failed?).returns(true)
        Runner.any_instance.expects(:execute_scenario_steps)
        Runner.any_instance.expects(:exit_code).returns(1)

        run_cmd
      end
    end

    describe 'run procedure by-tag' do
      let :command do
        %w[advanced procedure by-tag fallacious]
      end

      it 'exits with 1 if failed' do
        Scenario.any_instance.expects(:failed?).returns(true)
        Runner.any_instance.expects(:execute_scenario_steps)
        Runner.any_instance.expects(:exit_code).returns(1)

        run_cmd
      end
    end
  end
end
