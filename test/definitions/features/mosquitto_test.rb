require 'test_helper'

describe Features::Mosquitto do
  include DefinitionsTestHelper

  subject { Features::Mosquitto.new }
  let(:subject_ins) { Features::Mosquitto.any_instance }

  describe '#config_files' do
    it 'returns /etc/mosquitto' do
      _(subject.config_files).must_equal(['/etc/mosquitto'])
    end
  end

  describe '#services' do
    it 'is called mosquitto' do
      _(subject.services.first.name).must_equal('mosquitto')
    end

    it 'has priority 10' do
      _(subject.services.first.priority).must_equal(10)
    end
  end
end
