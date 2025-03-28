module Reports
  class AdvisorOnPremRemediations < ForemanMaintain::Report
    metadata do
      description 'Report number of remediations based on advisor rules from advisor on premise'
    end

    def run
      data_field('advisor_on_prem_remediations_enabled') { advisor_on_prem_remediations_enabled }
      data_field('advisor_on_prem_remediations_count') { advisor_on_prem_remediations_count }
    end

    def advisor_on_prem_remediations_enabled
      if @iop_enabled.nil?
        @iop_enabled = feature(:installer)&.answers&.dig(
          'foreman::plugin::rh_cloud', 'enable_iop_advisor_engine'
        ) || false
      end
      @iop_enabled
    end

    def advisor_on_prem_remediations_count
      if advisor_on_prem_remediations_enabled
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
