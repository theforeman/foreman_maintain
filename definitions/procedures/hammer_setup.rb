class Procedures::HammerSetup < ForemanMaintain::Procedure
  metadata do
    description 'Setup hammer'
    for_feature :hammer
    preparation_steps do
      Checks::ServicesUp.new
    end
  end

  def run
    if feature(:foreman_server)&.services_running?
      puts 'Configuring Hammer CLI...'
      result = feature(:hammer).setup_admin_access
      logger.info 'Hammer was configured successfully.' if result
    else
      skip("#{feature(:instance).product_name} server is not running. Hammer can't be setup now.")
    end
  end

  def necessary?
    if feature(:hammer)
      !feature(:hammer).check_connection
    else
      false
    end
  end
end
