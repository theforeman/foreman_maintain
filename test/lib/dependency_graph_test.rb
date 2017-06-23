require 'test_helper'

module ForemanMaintain
  describe DependencyGraph do
    let(:scenario) { Scenarios::PresentUpgrade::PreUpgradeChecks.new }

    subject { DependencyGraph.new(scenario.steps) }

    it 'should initialize with a graph and a collection' do
      refute_empty subject.collection
      refute_empty subject.graph
    end

    it 'do not add node if not found(nil)' do
      subject.add_to_graph(:some_key)
      refute subject.graph.key?(nil)
    end

    it 'add node if found' do
      subject.add_to_graph(:present_service_is_running)
      assert_empty subject.graph.fetch(:present_service_is_running)
    end

    it 'should find dependencies' do
      subject = DependencyGraph.new(scenario.steps << Checks::ExternalServiceIsAccessible.new)

      dependencies = [:external_service_is_accessible]

      subject.add_to_graph(:present_service_is_running, dependencies)
      childrens = subject.graph.fetch(:present_service_is_running)

      assert_equal 1, childrens.count
    end
  end
end
