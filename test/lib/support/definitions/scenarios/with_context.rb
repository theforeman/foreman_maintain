class Scenarios::WithContext < ForemanMaintain::Scenario
  def compose
    add_steps_with_context(Procedures::WithParam)
  end

  def set_context_mapping
    context.map(:param, Procedures::WithParam => :parameter)
  end
end
