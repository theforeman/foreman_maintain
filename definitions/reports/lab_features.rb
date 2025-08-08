# frozen_string_literal: true

module Reports
  class LabFeatures < ForemanMaintain::Report
    metadata do
      description 'Checks if lab features are enabled'
    end

    def run
      data_field('lab_features_enabled') do
        lab_features_setting = sql_setting('lab_features')
        return false if lab_features_setting.nil?

        # Parse the YAML setting value and convert to boolean
        YAML.safe_load(lab_features_setting) == true
      end
    end
  end
end
