require 'test_helper'

describe Checks::HostsEntryVerify do
  include DefinitionsTestHelper

  subject do
    Checks::HostsEntryVerify.new
  end

  it 'passes when hostname is localhost' do
    subject.stubs(:fetch_etc_hostname => 'localhost')
    result = run_check(subject)
    assert result.success?
  end

  it 'passes when alias is substring of FQDN' do
    subject.stubs(:fetch_etc_hostname => 'satellite.example.com')
    subject.stubs(:fetch_etc_hosts_entry_by_ip => ['127.10.10.1',
                                                   'satellite.example.com',
                                                   'satellite'])
    result = run_check(subject)
    assert result.success?
  end

  it 'raises warning when alias is not substring of FQDN' do
    subject.stubs(:fetch_etc_hostname => 'satellite.example.com')
    subject.stubs(:fetch_etc_hosts_entry_by_ip => ['127.10.10.1',
                                                   'satellite.example.com',
                                                   'sat1'])
    result = run_check(subject)
    assert result.warning?
  end
end
