class Procedures::Setup < ForemanMaintain::Procedure
  metadata do
    description 'Setup'
  end

  def run
    feature(:missing_service).restart
  end

  def necessary?
    !setup_already?
  end

  def setup_already?
    # to be stubbed to simulate it's necessary
    true
  end
end
