module ForemanMaintain
  class ReportCheck < Check
    attr_accessor :data

    def sql_count(sql)
      feature(:foreman_database).query(sql).first['count'].to_i
    end
  end
end