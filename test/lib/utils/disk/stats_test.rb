require 'test_helper'

module ForemanMaintain
  describe Utils::Disk::Stats do
    let(:stats) { Utils::Disk::Stats.new }

    it 'should initialize with empty hash' do
      assert_kind_of Hash, stats.data
      assert_empty(stats.data)
    end

    context 'stdout pushed data' do
      let(:performance) { '80 MB/sec' }

      it 'for single dir' do
        stats << mock(:dir => '/var', :performance => performance)

        assert_equal('Disk speed : 80 MB/sec', stats.stdout)
      end

      it 'should stdout pushed data' do
        stats.stubs(:data).returns(
          '/etc' => performance,
          '/var' => performance
        )

        assert_includes(stats.stdout.split("\n"), '/etc : 80 MB/sec')
        assert_includes(stats.stdout.split("\n"), '/var : 80 MB/sec')
      end
    end
  end
end
