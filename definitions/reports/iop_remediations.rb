module Reports
  class IopRemediations < ForemanMaintain::Report
    metadata do
      description 'Report number of remediations based on advisor rules from IoP'
    end

    def run
      data_field('iop_remediations_enabled') { iop_remediations_enabled }
      data_field('iop_remediations_count') { iop_remediations_count }
    end

    def iop_remediations_enabled
      if @iop_enabled.nil?
        @iop_enabled = !!feature(:iop)
      end
      @iop_enabled
    end

    def iop_remediations_count
      if iop_remediations_enabled
        return sql_count('
          job_invocations AS jobs
          INNER JOIN remote_execution_features AS rexf ON jobs.remote_execution_feature_id = rexf.id
          INNER JOIN template_invocations AS tinv ON jobs.id = tinv.job_invocation_id
          WHERE rexf.label = \'rh_cloud_remediate_hosts\'
          AND tinv.host_id IS NOT NULL
        ')
      end
    end
  end
end
