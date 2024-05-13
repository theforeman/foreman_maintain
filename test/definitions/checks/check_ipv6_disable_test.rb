require 'test_helper'

describe Checks::CheckIpv6Disable do
  include DefinitionsTestHelper

  subject { Checks::CheckIpv6Disable.new }

  it 'throws an error message when ipv6.disable=1 is set' do
    File.expects(:read).with('/proc/cmdline').returns('ipv6.disable=1')
    result = run_step(subject)

    assert result.fail?
  end

  it 'success when ipv6.disable=1 is not set' do
    File.expects(:read).with('/proc/cmdline').returns('test.net=0')
    result = run_step(subject)

    assert result.success?
  end
end
