class Features::ForemanDatabase < ForemanMaintain::Feature
  FOREMAN_DB_CONFIG = '/etc/foreman/database.yml'.freeze

  include ForemanMaintain::Concerns::BaseDatabase

  metadata do
    label :foreman_database

    confine do
      file_exist?(FOREMAN_DB_CONFIG)
    end
  end

  def configuration
    @configuration || load_configuration
  end

  def count(table, condition = '1=1')
    query("SELECT count(*) AS count FROM #{table} WHERE #{condition}").first['count'].to_i
  rescue CSV::MalformedCSVError
    error_msg = "table '#{table}' does not exist"
    logger.error(error_msg)
    error_msg
  end

  def query(sql)
    parse_csv(query_csv(sql))
  end

  def load_configuration
    config = YAML.load(File.read(FOREMAN_DB_CONFIG))
    @configuration = config['production']
  end

  def size(op, size)
    psql(query_size(op, size))
  end

  private

  def query_size(op, size)
    <<-SQL
      SELECT table_name, pg_size_pretty(total_bytes) AS total
           , pg_size_pretty(index_bytes) AS INDEX
           , pg_size_pretty(toast_bytes) AS toast
           , pg_size_pretty(table_bytes) AS TABLE
         FROM (
         SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes FROM (
             SELECT c.oid,nspname AS table_schema, relname AS TABLE_NAME
                     , c.reltuples AS row_estimate
                     , pg_total_relation_size(c.oid) AS total_bytes
                     , pg_indexes_size(c.oid) AS index_bytes
                     , pg_total_relation_size(reltoastrelid) AS toast_bytes
                 FROM pg_class c
                 LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                 WHERE relkind = 'r'
         ) a where a.total_bytes #{op} #{size}
       ) a order by total_bytes DESC;
    SQL
  end
end
