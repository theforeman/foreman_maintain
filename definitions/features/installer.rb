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
                        :katello
                      elsif find_package('capsule-installer')
                        :capsule
                      end
  end

  def answers
    case @installer_type
    when :scenarios
      last_scenario_answers
    when :katello
      load_answers(File.join(config_directory, 'katello-installer.yaml'))
    when :capsule
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
    when :katello
      '/etc/katello-installer'
    when :capsule
      '/etc/capsule-installer'
    end
  end

  def config_files
    Dir.glob(File.join(config_directory, '**/*'))
  end

  def last_scenario
    return nil unless with_scenarios?
    File.basename(last_scenario_config).split('.')[0]
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
