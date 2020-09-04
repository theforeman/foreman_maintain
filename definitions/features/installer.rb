class Features::Installer < ForemanMaintain::Feature
  metadata do
    label :installer

    confine do
      find_package('foreman-installer') ||
        find_package('katello-installer') ||
        find_package('capsule-installer')
    end
  end

  def initialize
    @installer_type = if find_package('foreman-installer')
                        :scenarios
                      elsif find_package('katello-installer')
                        :legacy_katello
                      elsif find_package('capsule-installer')
                        :legacy_capsule
                      end
  end

  def answers
    load_answers(configuration)
  end

  def configuration
    @configuration ||= YAML.load_file(config_file)
  end

  def config_file
    case @installer_type
    when :scenarios
      last_scenario_config
    when :legacy_katello
      File.join(config_directory, 'katello-installer.yaml')
    when :legacy_capsule
      File.join(config_directory, 'capsule-installer.yaml')
    end
  end

  def with_scenarios?
    @installer_type == :scenarios
  end

  def config_directory
    case @installer_type
    when :scenarios
      '/etc/foreman-installer'
    when :legacy_katello
      '/etc/katello-installer'
    when :legacy_capsule
      '/etc/capsule-installer'
    end
  end

  def custom_hiera_file
    @custom_hiera_file ||= File.join(config_directory, 'custom-hiera.yaml')
  end

  def can_upgrade?
    @installer_type == :scenarios || @installer_type == :legacy_katello
  end

  def config_files
    Dir.glob(File.join(config_directory, '**/*')) +
      [
        '/usr/local/bin/validate_postgresql_connection.sh'
      ]
  end

  def last_scenario
    return nil unless with_scenarios?

    File.basename(last_scenario_config).split('.')[0]
  end

  def installer_command
    case @installer_type
    when :scenarios
      if feature(:satellite)
        'satellite-installer'
      else
        'foreman-installer'
      end
    when :legacy_katello
      'katello-installer'
    when :legacy_capsule
      'capsule-installer'
    end
  end

  def run(arguments = '', exec_options = {})
    out = execute!("LANG=en_US.utf-8 #{installer_command} #{arguments}".strip, exec_options)
    @configuration = nil
    out
  end

  def upgrade(exec_options = {})
    run(installer_arguments, exec_options)
  end

  def installer_arguments
    installer_args = ' --disable-system-checks'
    unless check_min_version('foreman', '2.1') || check_min_version('foreman-proxy', '2.1')
      installer_args += ' --upgrade' if can_upgrade?
    end
    installer_args
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
