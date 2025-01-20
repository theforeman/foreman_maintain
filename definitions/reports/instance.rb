module Reports
  class Instance < ForemanMaintain::Report
    metadata do
      description 'Report information about the instance itself'
    end

    def run
      data_field('instance_uuid') { YAML.safe_load(sql_setting('instance_id')) }
    end
  end
end
