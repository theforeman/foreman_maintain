require 'test_helper'

module ForemanMaintain
  describe Utils::CommandRunner do
    let(:log) { StringIO.new }
    let(:logger) { Logger.new(log) }

    it 'hides passwords in the logs' do
      command = Utils::CommandRunner.new(logger, 'echo "Password is secret"',
                                         :hidden_patterns => [nil, 'secret'])
      command.run
      log.string.must_match "output of the command:\n Password is [FILTERED]\n"
      log.string.must_match 'Running command echo "Password is [FILTERED]" with stdin nil'
    end
  end
end
