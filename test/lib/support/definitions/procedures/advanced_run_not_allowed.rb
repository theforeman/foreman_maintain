class Procedures::AdvancedRunNotAllowed < ForemanMaintain::Procedure
  metadata do
    advanced_run false
  end

  def run; end
end
