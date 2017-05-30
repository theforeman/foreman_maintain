module ForemanMaintain
  describe DependencyGraph do
    let(:scenario) { Scenarios::PresentUpgrade.new }

    subject { DependencyGraph.new(scenario.steps) }

    it 'should initialize with a graph and a collection' do
      refute_empty subject.collection
      refute_empty subject.graph
    end

    it 'do not add node if not found(nil)' do
      subject.add(:some_key)
      refute subject.graph.key?(nil)
    end

    it 'add node if found' do
      subject.add(:present_service_is_running)
      assert_empty subject.graph.fetch(Checks::PresentServiceIsRunning)
    end

    it 'should find dependencies for Class, String and symbol' do
      subject.collection << Checks::ExternalServiceIsAccessible

      dependencies =
        [Checks::ExternalServiceIsAccessible,
         'Checks::ExternalServiceIsAccessible',
         :external_service_is_accessible]

      subject.add(:present_service_is_running, dependencies)
      childrens = subject.graph.fetch(Checks::PresentServiceIsRunning)

      assert_equal 3, childrens.count
      assert_equal Checks::ExternalServiceIsAccessible, *childrens.uniq
    end
  end
end
