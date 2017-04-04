class Scenarios::Deploy < ForemanMaintain::Scenario
  metadata do
    confine do
      feature(:delete_articles)
    end

    tags :release

    description 'Scenario: Deploy application'
  end

  def compose
    steps.concat(find_procedures(:release))
  end
end
