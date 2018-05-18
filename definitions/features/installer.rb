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
    case @installer_type
    when :scenarios
      last_scenario_answers
    when :legacy_katello
      load_answers(File.join(config_directory, 'katello-installer.yaml'))
    when :legacy_capsule
      load_answers(File.join(config_directory, 'capsule-installer.yaml'))
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
      if feature(:downstream)
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
    execute!("LANG=en_US.utf-8 #{installer_command} #{arguments}".strip, exec_options)
  end

  def upgrade(exec_options = {})
    arguments = '--upgrade' if can_upgrade?
    run(arguments, exec_options)
  end

  private

  def load_answers(config_file)
    config = YAML.load_file(config_file)
    YAML.load_file(config[:answer_file])
  end

  def scenario_answers(scenario)
    load_answers(File.join(config_directory, "scenarios.d/#{scenario}.yaml"))
  end

  def last_scenario_answers
    scenario_answers(last_scenario)
  end

  def last_scenario_config
    Pathname.new(File.join(config_directory, 'scenarios.d/last_scenario.yaml')).realpath.to_s
  end
end
