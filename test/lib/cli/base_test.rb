require 'test_helper'

require 'foreman_maintain/cli'

module ForemanMaintain
  describe Cli::Base do
    describe '.completion_dict' do
      class CommandB < Cli::Base
        option ['--filename'], 'FILE', 'File name', :completion => { :file => {} }
        parameter 'BACKUP_DIR', 'Path to backup dir', :completion => { :directory => {} }
        parameter 'BACKUP_MODE', 'Backup mode'
      end

      class CommandA < Cli::Base
        subcommand 'b', 'Descr', CommandB
        option ['--level', '-l'], 'LEVEL', 'descr'
        option ['--flag', '-f'], :flag, 'descr'
      end

      it 'collects options with multiple names' do
        desc = CommandA.completion_map
        desc.keys.must_include '--help'
        desc.keys.must_include '-h'
        desc['--help'].must_equal({})
      end

      it 'collects option with values' do
        desc = CommandA.completion_map
        desc['--level'].must_equal(:value => {})
      end

      it 'collects flag options' do
        desc = CommandA.completion_map
        desc['--flag'].must_equal({})
      end

      it 'collects subcommands and their options' do
        desc = CommandA.completion_map
        desc.keys.must_include 'b'
        desc['b'].keys.must_include '--filename'
      end

      it 'collects parameters' do
        desc = CommandB.completion_map
        desc[:params].must_equal([{ :directory => {} }, { :value => {} }])
      end

      it 'has no params key when params are missing' do
        desc = CommandA.completion_map
        desc.keys.wont_include :params
      end
    end
  end
end
