module Report
  class ActivationKeys < ForemanMaintain::Report
    metadata do
      description 'Report metrics related to Katello activation keys'
      confine do
        feature(:katello)
      end
    end

    def run
      data_field('activation_keys_count') { activation_keys_count }
      data_field('activation_keys_multi_cv_count') { activation_keys_multi_cv_count }
    end

    private

    def activation_keys_count
      sql_count(
        'katello_content_view_environment_activation_keys',
        column: 'DISTINCT activation_key_id'
      )
    end

    def activation_keys_multi_cv_count
      sql_as_count(
        "COUNT(*)",
        <<~SQL
          (
            SELECT activation_key_id
            FROM katello_content_view_environment_activation_keys
            GROUP BY activation_key_id
            HAVING COUNT(*) > 1
          ) AS multi_cve_keys
        SQL
      )
    end
  end
end
