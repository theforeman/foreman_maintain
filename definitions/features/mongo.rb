class Features::Mongo < ForemanMaintain::Feature
  # assume mongo is installed when there is Pulp
  PULP_DB_CONFIG = '/etc/pulp/server.conf'.freeze

  attr_reader :configuration
  metadata do
    label :mongo

    confine do
      feature(:pulp)
    end
  end

  def services
    core.services
  end

  def data_dir
    '/var/lib/mongodb'
  end

  def config_files
    [config_file] + (local? ? core.server_config_files : [])
  end

  def config_file
    PULP_DB_CONFIG
  end

  def initialize
    @configuration = load_db_config(config_file)
  end

  def core
    if @core.nil?
      version = server_version
      @core = if version =~ /^3\.4/
                logger.debug("Mongo #{version} detected, using commands from rh-mongodb34 SCL")
                ForemanMaintain::Utils::MongoCore34.new
              else
                logger.debug("Mongo #{version} detected, using default commands")
                ForemanMaintain::Utils::MongoCore.new
              end
    end
    @core
  end

  def local?
    ['localhost', '127.0.0.1', hostname].include?(configuration['host'])
  end

  def base_command(command, config = configuration, args = '')
    if config['ssl']
      ssl = ' --ssl'
      if config['ca_path']
        ca_cert = " --sslCAFile #{config['ca_path']}"
        client_cert = " --sslPEMKeyFile #{config['ssl_certfile']}" if config['ssl_certfile']
      end
    end
    username = " -u #{config['username']}" if config['username']
    password = " -p #{config['password']}" if config['password']
    host = "--host #{config['host']} --port #{config['port']}"
    "#{command}#{username}#{password} #{host}#{ssl}#{ca_cert}#{client_cert} #{args}"
  end

  def mongo_command(args, config = configuration)
    base_command(core.client_command, config, "#{args} #{config['name']}")
  end

  def dump(target, config = configuration)
    execute!(base_command(core.dump_command, config, "-d #{config['name']} --out #{target}"),
             :hidden_patterns => [config['password']].compact)
  end

  def restore(dir, config = configuration)
    cmd = base_command(core.restore_command, config, File.join(dir, config['name']))
    execute!(cmd, :hidden_patterns => [config['password']].compact)
  end

  def dropdb(config = configuration)
    execute!(mongo_command("--eval 'db.dropDatabase()'", config),
             :hidden_patterns => [config['password']].compact)
  end

  def ping(config = configuration)
    execute?(mongo_command("--eval 'ping:1'"),
             :hidden_patterns => [config['password']].compact)
  end

  def server_version(config = configuration)
    # do not use any core methods as we need this prior the core is created
    version = execute(base_command('mongo', config, "--eval 'db.version()' #{config['name']}"),
                      :hidden_patterns => [config['password']].compact)
    version.split("\n").last
  end

  def backup_local(backup_file, extra_tar_options = {})
    dir = extra_tar_options.fetch(:data_dir, nil) || data_dir
    logger.info("Backup of Mongo DB at #{dir} into #{backup_file}")
    logger.debug(extra_tar_options.inspect)
    FileUtils.cd(dir) do
      tar_options = {
        :archive => backup_file,
        :command => 'create',
        :exclude => ['mongod.lock'],
        :transform => 's,^,var/lib/mongodb/,S',
        :files => '*'
      }.merge(extra_tar_options)
      feature(:tar).run(tar_options)
    end
  end

  def find_base_directory(directory)
    find_dir_containing_file(directory, 'mongod.lock')
  end

  private

  def norm_value(value)
    value = value.strip
    case value
    when 'true'
      true
    when 'false'
      false
    else
      value
    end
  end

  def load_db_config(config)
    cfg = read_db_section(config)
    if cfg['seeds']
      seed = cfg['seeds'].split(',').first
      host, port = seed.split(':')
    end
    cfg['host'] = host || 'localhost'
    cfg['port'] = port || '27017'
    cfg
  end

  # rubocop:disable  Metrics/MethodLength
  def read_db_section(config)
    cfg = {}
    section = nil
    File.readlines(config).each do |line|
      case line
      when /^\s*#/
        next # skip comments
      when /^\s*$/
        next # skip empty lines
      when /\[([^\]]+)\]/
        section = Regexp.last_match(1)
        next
      else
        if section == 'database'
          key, value = line.split(':', 2)
          cfg[key.strip] = norm_value(value)
        end
      end
    end
    cfg
  end
  # rubocop:enable  Metrics/MethodLength
end
