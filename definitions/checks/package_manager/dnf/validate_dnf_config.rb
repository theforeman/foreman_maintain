module Checks::PackageManager
  module Dnf
    class ValidateDnfConfig < ForemanMaintain::Check
      metadata do
        label :validate_dnf_config
        description 'Check to validate dnf configuration before upgrade'
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

      # rubocop:disable Metrics/LineLength
      def failure_message(final_result)
        verb_string = final_result[:matched_keys].length > 1 ? 'are' : 'is'

        "#{final_result[:matched_keys].join(',')} #{verb_string} set in /etc/dnf/dnf.conf as below:"\
        "\n#{final_result[:grep_output]}"\
        "\nUnset this configuration as it is risky while dnf update or upgrade!"
      end
      # rubocop:enable Metrics/LineLength

      def verify_config_options
        result = {}
        combined_regex = dnf_config_options.values.join('|')
        result[:grep_output] = execute_grep_cmd(combined_regex)
        result[:matched_keys] = dnf_config_options.keys.select do |key|
          result[:grep_output].include?(key)
        end
        result
      end

      def execute_grep_cmd(regex_string)
        execute_with_status("grep -iE '#{regex_string}' /etc/dnf/dnf.conf")[1]
      end

      def dnf_config_options
        @dnf_config_options ||= {
          'exclude' => '^exclude\s*=\s*\S+.*$',
        }
      end
    end
  end
end
