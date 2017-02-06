class Features::ForemanDatabase < ForemanMaintain::Feature
  feature_name :foreman_database

  detect do
    self.new if File.exists?('/etc/foreman/database.yml')
  end

  def query(sql)
    parse_csv(psql(%{COPY (#{sql}) TO STDOUT WITH CSV HEADER)}))
  end

  def psql(query)
    execute("su - postgres -c 'psql -d foreman'", query)
  end
end
