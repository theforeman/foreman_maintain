class Features::ForemanDatabase < ForemanMaintain::Feature
  label :foreman_database

  confine do
    File.exist?('/etc/foreman/database.yml')
  end

  def query(sql)
    parse_csv(psql(%{COPY (#{sql}) TO STDOUT WITH CSV HEADER)}))
  end

  def psql(query)
    execute("su - postgres -c 'psql -d foreman'", query)
  end
end
