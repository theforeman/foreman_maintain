class Procedures::HammerSetup < ForemanMaintain::Procedure
  metadata do
    description 'Setup hammer'
    for_feature :hammer
  end

  def run
    if feature(:foreman_server) && ForemanMaintain::Utils.system_service('httpd', 30).running?
      puts 'Configuring Hammer CLI...'
      result = feature(:hammer).setup_admin_access
      logger.info 'Hammer was configured successfully.' if result
    else
      skip("#{feature(:instance).product_name} server is not running. Hammer can't be setup now.")
    end
  end

  def necessary?
    !feature(:hammer).check_connection
  end
end
