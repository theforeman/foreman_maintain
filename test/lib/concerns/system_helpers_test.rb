require 'test_helper'

class FakeSystem
  include ForemanMaintain::Concerns::SystemHelpers
end

module ForemanMaintain
  describe Concerns::SystemHelpers do
    let(:system) { FakeSystem.new }

    describe '.version' do
      it 'can parse a normal version' do
        assert system.version('1.2.3')
      end

      it 'can parse a weird nightly package version' do
        assert system.version('9999-3.4.0-bullseye+scratchbuild+20220623140206')
        assert system.version('1.4.7-1~tfm+1')
      end
    end
  end
end
