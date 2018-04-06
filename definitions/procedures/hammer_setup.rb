class Procedures::HammerSetup < ForemanMaintain::Procedure
  metadata do
    description 'Setup hammer'
    for_feature :hammer
  end

  def run
    result = feature(:hammer).setup_admin_access
    logger.info 'Hammer was configured successfully.' if result
  end

  def necessary?
    !feature(:hammer).check_connection
  end
end
