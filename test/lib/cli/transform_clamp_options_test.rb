class Definition
  def description
    ''
  end

  def label
    :mock
  end

  def params
    {
      :name     => param_name,
      :state    => param_state,
      :packages => param_packages
    }
  end

  def param_name
    ForemanMaintain::Param.new(:name, 'Definitaion name', {})
  end

  def param_state
    ForemanMaintain::Param.new(:state, 'Definitaion state', :required => true)
  end

  def param_packages
    ForemanMaintain::Param.new(:packages, 'Packages to Install', :array => true)
  end
end

Option = Struct.new(:read_method, :switches)

module ForemanMaintain
  module Cli
    class MockCommand < Base
      include ForemanMaintain::Cli::TransformClampOptions

      class << self
        def definition
          Definition.new
        end

        def recognised_options
          [
            { :read_method => :state, :switches => ['--state'] },
            { :read_method => :assumeyes, :switches => ['--assumeyes'] }
          ].map { |options| Option.new(options[:read_method], options[:switches]) }
        end
      end

      def state
        nil
      end

      def execute
        get_params_for(Definition.new)
      end
    end
  end
end

describe ForemanMaintain::Cli::TransformClampOptions do
  subject { ForemanMaintain::Cli::MockCommand.new('', {}) }

  describe 'OptionsToParams' do
    it 'get_params_for(definition)' do
      assert_kind_of Hash, subject.execute
    end

    it 'options_to_params' do
      assert_nil subject.options_to_params.fetch(:state)
    end
  end

  describe 'ParamsToOptions' do
    subject { ForemanMaintain::Cli::MockCommand }

    let(:definition) { Definition.new }

    it 'params_to_options(params)' do
      options = subject.params_to_options(definition.params)
      refute_empty options, 'ParamsToOptions#params_to_options returned empty!'
    end

    describe 'param_to_option(param)' do
      it 'should return clamp object' do
        option = subject.param_to_option(definition.param_name)
        assert_kind_of Clamp::Option::Definition, option
      end

      it 'set require flag' do
        option = subject.param_to_option(definition.param_state)
        assert option.required?, '--state is expected to be required'
      end
    end
  end
end
