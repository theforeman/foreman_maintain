require 'test_helper'

describe Features::Tar do
  include DefinitionsTestHelper

  subject { Features::Tar.new }
  context '#validate_volume_size' do
    it 'raises Validation error with incorrect --tape-length formats' do
      error = ForemanMaintain::Error::Validation

      assert_raises(error) { subject.validate_volume_size('blah') }
      assert_raises(error) { subject.validate_volume_size('') }
      assert_raises(error) { subject.validate_volume_size(nil) }
      assert_raises(error) { subject.validate_volume_size('  ') }
      assert_raises(error) { subject.validate_volume_size('20394023xerror') }
      assert_raises(error) { subject.validate_volume_size('20Z') }
      assert_raises(error) { subject.validate_volume_size('20GB') }
      assert_raises(error) { subject.validate_volume_size('20xG') }
      assert_raises(error) { subject.validate_volume_size('20Gx') }
      assert_raises(error) { subject.validate_volume_size('B') }
      assert_raises(error) { subject.validate_volume_size('W') }
      assert_raises(error) { subject.validate_volume_size('-10B') }
    end

    it 'validate the correct --tape-length formats' do
      _(subject.validate_volume_size('10B')).must_equal true
      _(subject.validate_volume_size('1000b')).must_equal true
      _(subject.validate_volume_size('4000c')).must_equal true
      _(subject.validate_volume_size('2134G')).must_equal true
      _(subject.validate_volume_size('2343K')).must_equal true
      _(subject.validate_volume_size('343k')).must_equal true
      _(subject.validate_volume_size('34M')).must_equal true
      _(subject.validate_volume_size('4P')).must_equal true
      _(subject.validate_volume_size('2T')).must_equal true
      _(subject.validate_volume_size('1204w')).must_equal true
      _(subject.validate_volume_size('1204')).must_equal true
    end
  end
end
