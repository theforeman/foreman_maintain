module Checks
  module Foreman
    class TuningRequirements < ForemanMaintain::Check
      metadata do
        label :check_tuning_requirements
        tags :pre_upgrade
        description 'Check if system requirements match current tuning profile'
        confine do
          feature(:katello)
        end
        do_not_whitelist
      end

      def run
        failure_message = check_tuning_profile
        fail! failure_message if failure_message
      end

      def check_tuning_profile
        installer_config = feature(:installer).configuration
        tuning_profile = installer_config[:facts]['tuning']

        cpu_message = check_cpu_cores(tuning_profile)
        memory_message = check_memory(tuning_profile)

        return unless cpu_message || memory_message

        message = failure_message(tuning_profile)
        if cpu_message
          message += "#{cpu_message}\n"
        end
        if memory_message
          message += "#{memory_message}\n"
        end

        message
      end

      def check_memory(tuning_profile)
        # Check if it's actually 90% of the required. If a crash kernel is enabled
        # then the reported total memory is lower than in reality.
        kb_to_gb = (1024 * 1024)
        memory_percentile = 0.9
        tuning_memory = tuning_sizes[tuning_profile][:memory]
        system_memory = memory.to_i

        unless system_memory.to_i >= (tuning_memory * kb_to_gb * memory_percentile)
          "The system memory is #{system_memory / kb_to_gb} GB but the currently configured tuning profile requires #{tuning_memory} GB." # rubocop:disable Metrics/LineLength
        end
      end

      def check_cpu_cores(tuning_profile)
        tuning_cpu_cores = tuning_sizes[tuning_profile][:cpu_cores]
        system_cpu_cores = cpu_cores

        unless system_cpu_cores.to_i >= tuning_cpu_cores
          "The number of CPU cores for the system is #{system_cpu_cores} but the currently configured tuning profile requires #{tuning_cpu_cores}." # rubocop:disable Metrics/LineLength
        end
      end

      def tuning_sizes
        {
          'development' => { cpu_cores: 1, memory: 6 },
          'default' => { cpu_cores: 4, memory: 20 },
          'medium' => { cpu_cores: 8, memory: 32 },
          'large' => { cpu_cores: 16, memory: 64 },
          'extra-large' => { cpu_cores: 32, memory: 128 },
          'extra-extra-large' => { cpu_cores: 48, memory: 256 }
        }
      end

      def failure_message(tuning_profile)
        <<-MESSAGE.strip_heredoc
        \nERROR: The installer is configured to use the #{tuning_profile} tuning profile and does not meet the requirements.
        MESSAGE
      end
    end
  end
end
