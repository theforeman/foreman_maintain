class Features::CandlepinDatabase < ForemanMaintain::Feature
  CANDLEPIN_DB_CONFIG = '/etc/candlepin/candlepin.conf'.freeze

  include ForemanMaintain::Concerns::BaseDatabase

  metadata do
    label :candlepin_database

    confine do
      file_nonzero?(CANDLEPIN_DB_CONFIG)
    end
  end

  def services
    [
      system_service('postgresql', 10, :component => 'candlepin',
                                       :db_feature => feature(:candlepin_database)),
    ]
  end

  def configuration
    @configuration || load_configuration
  end

  def validate_available_in_cpdb?
    check_option_using_cpdb_help('validate')
  end

  def check_option_using_cpdb_help(option_name, parent_cmd = '')
    parent_cmd = '/usr/share/candlepin/cpdb' if parent_cmd.empty?
    help_cmd = "#{parent_cmd} --help |  grep -c '\\-\\-#{option_name}'"
    execute?(help_cmd)
  end

  def execute_cpdb_validate_cmd
    main_cmd = cpdb_validate_cmd
    return [true, nil] if main_cmd.empty?
    main_cmd += format_shell_args(
      '-u' => configuration['username'], '-p' => configuration[%(password)]
    )
    main_cmd += format_shell_args(extend_with_db_options)
    execute_with_status(main_cmd, :hidden_patterns => [configuration['password']])
  end

  def env_content_ids_with_null_content
    sql = <<-SQL
      SELECT ec.id
      FROM cp_env_content ec
      LEFT JOIN cp_content c ON ec.contentid = c.id WHERE c.id IS NULL
    SQL
    query(sql).map { |r| r['id'] }
  end

  private

  def load_configuration
    raw_config = File.read(CANDLEPIN_DB_CONFIG)
    full_config = Hash[raw_config.scan(/(^[^#\n][^=]*)=(.*)/)]
    uri_regexp = %r{://(([^/:]*):?([^/]*))/([^?]*)\??(ssl=([^&]*))?}
    url = full_config['jpa.config.hibernate.connection.url']
    uri = uri_regexp.match(url)
    @configuration = {
      'username' => full_config['jpa.config.hibernate.connection.username'],
      'password' => full_config['jpa.config.hibernate.connection.password'],
      'database' => uri[4],
      'host' => uri[2],
      'port' => uri[3] || '5432',
      'ssl' => (fetch_extra_param(url, 'ssl') == 'true'),
      'sslfactory' => fetch_extra_param(url, 'sslfactory'),
      'driver_class' => full_config['jpa.config.hibernate.connection.driver_class'],
      'url' => url,
    }
  end

  def extend_with_db_options
    db_options = { '-d' => configuration['database'] }
    if check_option_using_cpdb_help('dbhost')
      db_options['--dbhost'] = configuration['host']
      db_options['--dbport'] = configuration['port']
    end
    db_options
  end

  def fetch_extra_param(url, key_name)
    query_string = url.split('?')[1]
    return nil unless query_string
    output = /#{key_name}=([^&]*)?/.match(query_string)
    output[1] if output
  end

  def cpdb_validate_cmd
    return '' unless check_option_using_cpdb_help('validate')
    cmd = '/usr/share/candlepin/cpdb --validate'
    return cmd unless check_option_using_cpdb_help('verbose', cmd)
    cmd += ' --verbose'
    cmd
  end
end
