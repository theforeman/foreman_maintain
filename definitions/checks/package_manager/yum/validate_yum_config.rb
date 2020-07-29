module Checks::PackageManager
  module Yum
    class ValidateYumConfig < ForemanMaintain::Check
      metadata do
        label :validate_yum_config
        description 'Check to validate yum configuration before upgrade'
        tags :pre_upgrade
      end

      def run
        final_result = verify_config_options
        assert(
          final_result[:matched_keys].empty?,
          failure_message(final_result)
        )
      end

      private

      def failure_message(final_result)
        verb_string = final_result[:matched_keys].length > 1 ? 'are' : 'is'

        "#{final_result[:matched_keys].join(',')} #{verb_string} set in /etc/yum.conf as below:"\
        "\n#{final_result[:grep_output]}"\
        "\nUnset this configuration as it is risky while yum update or upgrade!"
      end

      def verify_config_options
        result = {}
        combined_regex = yum_config_options.values.join('|')
        result[:grep_output] = execute_grep_cmd(combined_regex)
        result[:matched_keys] = yum_config_options.keys.select do |key|
          result[:grep_output].include?(key)
        end
        result
      end

      def execute_grep_cmd(regex_string)
        execute_with_status("grep -iE '#{regex_string}' /etc/yum.conf")[1]
      end

      def yum_config_options
        @yum_config_options ||= {
          'exclude' => '^exclude\s*=\s*\S+.*$',
          'clean_requirements_on_remove' =>
            '^clean_requirements_on_remove\s*=\S*(1|yes|true)$'
        }
      end
    end
  end
end
