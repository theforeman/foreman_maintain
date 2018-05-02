require 'test_helper'

describe Features::Tar do
  include DefinitionsTestHelper

  subject { Features::Tar.new }
  context '#validate_volume_size' do
    it 'raises Validation error with incorrect --tape-length formats' do
      error = ForemanMaintain::Error::Validation
      proc { subject.validate_volume_size('blah') }.must_raise error
      proc { subject.validate_volume_size('') }.must_raise error
      proc { subject.validate_volume_size(nil) }.must_raise error
      proc { subject.validate_volume_size('  ') }.must_raise error
      proc { subject.validate_volume_size('20394023x') }.must_raise error
      proc { subject.validate_volume_size('20Z') }.must_raise error
      proc { subject.validate_volume_size('20GB') }.must_raise error
      proc { subject.validate_volume_size('20xG') }.must_raise error
      proc { subject.validate_volume_size('20Gx') }.must_raise error
      proc { subject.validate_volume_size('B') }.must_raise error
      proc { subject.validate_volume_size('W') }.must_raise error
      proc { subject.validate_volume_size('-10B') }.must_raise error
    end

    it 'validate the correct --tape-length formats' do
      subject.validate_volume_size('10B').must_equal true
      subject.validate_volume_size('1000b').must_equal true
      subject.validate_volume_size('4000c').must_equal true
      subject.validate_volume_size('2134G').must_equal true
      subject.validate_volume_size('2343K').must_equal true
      subject.validate_volume_size('343k').must_equal true
      subject.validate_volume_size('34M').must_equal true
      subject.validate_volume_size('4P').must_equal true
      subject.validate_volume_size('2T').must_equal true
      subject.validate_volume_size('1204w').must_equal true
      subject.validate_volume_size('1204').must_equal true
    end
  end
end
