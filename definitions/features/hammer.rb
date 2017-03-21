require 'yaml'
class Features::Hammer < ForemanMaintain::Feature
  metadata do
    label :hammer
  end

  def password_available?
    setting_exists?(:password)
  end

  def username_available?
    setting_exists?(:username)
  end

  def settings
    @settings ||= load_settings
  end

  # Run a hammer command #
  def run_command(args)
    execute("#{command_base} #{args}", :hidden_patterns => hidden_patterns)
  end

  private

  def command_base
    "hammer -u #{shellescape(settings[:username])} -p #{shellescape(settings[:password])}"
  end

  # patterns hidden from logs
  def hidden_patterns
    [settings[:password], shellescape(settings[:password])]
  end

  def setting_exists?(key)
    settings &&
      settings.key?(key) &&
      !settings[key].nil? &&
      !settings[key].empty?
  end

  def load_settings
    config_files = ['~/.hammer/', '/etc/hammer/', "#{::RbConfig::CONFIG['sysconfdir']}/hammer/",
                    './config/'].uniq
    load_from_paths(config_files)
  end

  def load_from_paths(files)
    files.reverse.each do |path|
      full_path = File.expand_path path
      next unless File.directory? full_path
      Dir.glob(File.join(full_path, 'cli.modules.d/foreman.yml')).sort.each do |f|
        load_from_file(f)
      end
    end
    @settings
  end

  def load_from_file(file_path)
    return unless File.file?(file_path)
    begin
      config = YAML.load(File.open(file_path))
      return unless config
      @settings ||= {}
      @settings.merge!(config[:foreman])
    rescue => e
      raise "Couldn't load configuration file: #{e.message}"
    end
  end
end
