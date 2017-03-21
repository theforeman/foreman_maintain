class Features::ForemanDatabase < ForemanMaintain::Feature
  metadata do
    label :foreman_database

    confine do
      File.exist?('/etc/foreman/database.yml')
    end
  end

  def query(sql)
    parse_csv(query_csv(sql))
  end

  def query_csv(sql)
    psql(%{COPY (#{sql}) TO STDOUT WITH CSV HEADER})
  end

  def psql(query)
    execute("su - postgres -c 'psql -d foreman'", :stdin => query)
  end
end
