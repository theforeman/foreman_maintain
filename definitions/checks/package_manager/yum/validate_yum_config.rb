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
          final_result.keys.empty?,
          failure_message(final_result)
        )
      end

      private

      def failure_message(final_result)
        verb_string = final_result.keys.length > 1 ? 'are' : 'is'

        "In /etc/yum.conf, #{final_result.keys.join(',')} #{verb_string} set as below:"\
        "\n#{final_result.values.join("/\n")}"\
        "\nUnset this configuration as it is risky while yum update or upgrade!"
      end

      def verify_config_options
        result = {}
        yum_config_options.each do |config_name, reg_ex|
          grep_output = execute_grep_cmd(config_name)
          if grep_output.downcase.match(reg_ex)
            result[config_name] = grep_output
          end
        end
        result
      end

      def execute_grep_cmd(config_name)
        execute_with_status("grep -iw #{config_name} /etc/yum.conf")[1]
      end

      def yum_config_options
        @yum_config_options ||= {
          'exclude' => /^exclude\s*=\s*\S+.*$/,
          'clean_requirements_on_remove' =>
            /^clean_requirements_on_remove\s*=\S*(1|yes|true)$/
        }
      end
    end
  end
end
