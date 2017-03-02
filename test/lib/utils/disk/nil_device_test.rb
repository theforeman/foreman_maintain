require 'test_helper'

module ForemanMaintain
  describe Utils::Disk::NilDevice do
    let(:null) { described_class::NULL }

    it 'should initialze with dir, name, unit and read_speed with NULL' do
      null_device = described_class.new

      assert_equal(null, null_device.dir)
      assert_equal(null, null_device.name)
      assert_equal(null, null_device.unit)
      assert_equal(null, null_device.read_speed)
    end
  end
end
