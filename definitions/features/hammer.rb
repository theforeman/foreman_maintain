require 'uri'

class Features::Hammer < ForemanMaintain::Feature
  attr_reader :configuration, :config_files

  metadata do
    label :hammer
    confine do
      # FIXME: How does this run on proxy?
      find_package('rubygem-hammer_cli') || find_package('tfm-rubygem-hammer_cli')
    end
  end

  def initialize
    @configuration = { :foreman => {} }
    @config_files = []
    @ready = nil
    load_configuration
  end

  def config_directories
    [
      '~/.hammer/',
      '/etc/hammer/'
    ]
  end

  def setup_admin_access
    return true if check_connection
    logger.info('Hammer setup is not valid. Fixing configuration.')
    custom_config = { :foreman => { :username => username } }
    custom_config = on_invalid_host(custom_config)
    custom_config = on_missing_password(custom_config) # get password from answers
    custom_config = on_invalid_password(custom_config) # get password from answers
    ask_password_and_check(custom_config) unless ready?
    config_error unless ready?
    ready?
  end

  def ready?
    setup_admin_access if @ready.nil?
    @ready
  end

  def check_connection
    @ready = _check_connection
  end

  def server_uri
    "https://#{hostname}/"
  end

  def custom_config_file
    fm_config_dir = File.dirname(ForemanMaintain.config_file)
    File.join(fm_config_dir, 'foreman-maintain-hammer.yml')
  end

  def command_base
    if File.exist?(custom_config_file)
      %(RUBYOPT='-W0' LANG=en_US.utf-8 hammer -c "#{custom_config_file}" --interactive=no)
    else
      %(RUBYOPT='-W0' LANG=en_US.utf-8 hammer --interactive=no)
    end
  end

  # Run a hammer command, examples:
  # run('host list')
  def run(args)
    setup_admin_access
    execute("#{command_base} #{args}")
  end

  private

  def on_invalid_host(custom_config)
    hammer_host = URI.parse(configuration[:foreman][:host]).host if configuration[:foreman][:host]
    if hammer_host != hostname
      logger.info("Matching hostname was not found in hammer configs. Using #{server_uri}")
      custom_config[:foreman][:host] = server_uri
    end
    custom_config
  end

  def on_invalid_password(custom_config)
    admin_password = password_from_answers(custom_config[:foreman][:username])
    if !ready? && custom_config[:foreman][:password] != admin_password
      msg = 'Invalid admin password was found in hammer configs. Looking into installer answers'
      logger.info(msg)
      custom_config[:foreman][:password] = admin_password
      save_config_and_check(custom_config)
    end
    custom_config
  end

  def ask_password_and_check(custom_config)
    custom_config[:foreman][:password] = ask('Hammer admin password:', :password => true)
    save_config_and_check(custom_config)
    custom_config
  end

  def config_error
    raise ForemanMaintain::HammerConfigurationError, 'Hammer configuration failed: '\
                  'Is the admin credential from the file' \
                  " #{custom_config_file} correct?\n" \
                  'Is the server down?'
  end

  def on_missing_password(custom_config)
    if admin_password_missing?
      msg = 'Admin password was not found in hammer configs. Looking into installer answers'
      logger.info(msg)
      custom_config[:foreman][:password] = password_from_answers(custom_config[:foreman][:username])
    end
    save_config_and_check(custom_config)
    custom_config
  end

  def admin_password_missing?
    configuration[:foreman][:password].nil? ||
      configuration[:foreman][:password].empty? ||
      configuration[:foreman][:username] != username
  end

  def exec_hammer_cmd(cmd, required_json = false)
    response = run(cmd)
    json_str = parse_json(response) if required_json
    json_str ? json_str : response
  end

  def load_configuration
    config_directories.reverse.each do |path|
      full_path = File.expand_path path
      next unless File.directory? full_path
      load_from_file(File.join(full_path, 'cli_config.yml'))
      load_from_file(File.join(full_path, 'defaults.yml'))
      # load config for modules
      Dir.glob(File.join(full_path, 'cli.modules.d/*.yml')).sort.each do |f|
        load_from_file(f)
      end
    end
  end

  def load_from_file(file_path)
    if File.file? file_path
      config = YAML.load(File.open(file_path))
      if config
        ForemanMaintain::Utils::HashTools.deep_merge!(@configuration, config)
        @config_files << file_path
      end
    end
  end

  def username
    return 'admin' unless feature(:installer)
    feature(:installer).initial_admin_username
  end

  def password_from_answers(config_username)
    return nil unless feature(:installer)
    return nil unless config_username == feature(:installer).initial_admin_username
    feature(:installer).initial_admin_password
  end

  def save_config_and_check(config)
    save_config(config)
    check_connection
  end

  def save_config(config)
    File.open(custom_config_file, 'w', 0o600) { |f| f.puts YAML.dump(config) }
  end

  def _check_connection
    `#{command_base} user list --per-page 1 2>&1` && $CHILD_STATUS.exitstatus == 0
  end
end
