class Features::Installer < ForemanMaintain::Feature
  metadata do
    label :installer

    confine do
      find_package('foreman-installer')
    end
  end

  def answers
    load_answers(configuration)
  end

  def configuration
    @configuration ||= YAML.load_file(config_file)
  end

  def config_file
    last_scenario_config
  end

  def config_directory
    '/etc/foreman-installer'
  end

  def custom_hiera_file
    @custom_hiera_file ||= File.join(config_directory, 'custom-hiera.yaml')
  end

  def config_files
    Dir.glob(File.join(config_directory, '**/*')) +
      [
        '/opt/puppetlabs/puppet/cache/foreman_cache_data',
        '/opt/puppetlabs/puppet/cache/pulpcore_cache_data',
      ]
  end

  def last_scenario
    File.basename(last_scenario_config).split('.')[0]
  end

  def installer_command
    if feature(:satellite)
      'satellite-installer'
    else
      'foreman-installer'
    end
  end

  def run(arguments = '', exec_options = {})
    out = execute!("#{installer_command} #{arguments}".strip, exec_options)
    @configuration = nil
    out
  end

  def run_with_status(arguments = '', exec_options = {})
    cmd_with_arguments = "#{installer_command} #{arguments}".strip
    cmd_status, out = execute_with_status(cmd_with_arguments, exec_options)
    @configuration = nil
    [cmd_status, out]
  end

  def initial_admin_username
    feature(:installer).answers['foreman']['initial_admin_username'] ||
      feature(:installer).answers['foreman']['admin_username']
  end

  def initial_admin_password
    feature(:installer).answers['foreman']['initial_admin_password'] ||
      feature(:installer).answers['foreman']['admin_password']
  end

  def lock_package_versions?
    !!(configuration[:custom] && configuration[:custom][:lock_package_versions])
  end

  def lock_package_versions_supported?
    !(configuration[:custom] && configuration[:custom][:lock_package_versions]).nil?
  end

  private

  def load_answers(config)
    YAML.load_file(config[:answer_file])
  end

  def last_scenario_config
    Pathname.new(File.join(config_directory, 'scenarios.d/last_scenario.yaml')).realpath.to_s
  end
end
