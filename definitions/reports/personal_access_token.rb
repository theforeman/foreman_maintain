# frozen_string_literal: true

module Reports
  class PersonalAccessToken < ForemanMaintain::Report
    metadata do
      description 'Report about Personal Access Token usage'
    end

    def run
      # Total count of non-revoked personal access tokens
      data_field('pat_counts') do
        sql_count('personal_access_tokens WHERE revoked = false')
      end

      # Count of tokens that were used recently (updated in last 2 months)
      data_field('pat_recently_used_count') do
        sql_count("personal_access_tokens WHERE updated_at >= NOW() - INTERVAL '2 months'")
      end

      # Count of revoked personal access tokens
      data_field('revoked_pats_count') do
        sql_count('personal_access_tokens WHERE revoked = true')
      end
    end
  end
end
