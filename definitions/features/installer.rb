class Features::Installer < ForemanMaintain::Feature
  metadata do
    label :installer

    confine do
      find_package('foreman-installer') && !config_file.nil?
    end
  end

  def answers
    YAML.load_file(answer_file)
  end

  def configuration
    @configuration ||= YAML.load_file(self.class.config_file)
  end

  def self.config_file
    last_scenario_config
  end

  def self.config_directory
    '/etc/foreman-installer'
  end

  def custom_hiera_file
    @custom_hiera_file ||= File.join(self.class.config_directory, 'custom-hiera.yaml')
  end

  def config_files
    paths = [
      self.class.config_directory,
      '/opt/puppetlabs/puppet/cache/foreman_cache_data',
      '/opt/puppetlabs/puppet/cache/pulpcore_cache_data',
    ]
    paths << answer_file unless answer_file.start_with?("#{self.class.config_directory}/")
    paths
  end

  def last_scenario
    File.basename(self.class.last_scenario_config).split('.')[0]
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

  def self.last_scenario_config
    if File.exist?(last_scenario_yaml)
      Pathname.new(last_scenario_yaml).realpath.to_s
    end
  end

  def self.last_scenario_yaml
    File.join(config_directory, 'scenarios.d/last_scenario.yaml')
  end

  private

  def answer_file
    configuration[:answer_file]
  end
end
