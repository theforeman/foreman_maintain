module Checks
  module Disk
    class Performance < ForemanMaintain::Check
      metadata do
        label :disk_performance
        description 'Check for recommended disk speed of pulp, mongodb, pgsql dir.'
        tags :pre_upgrade
        preparation_steps { Procedures::Packages::Install.new(:packages => %w[fio]) }

        confine do
          feature(:instance).pulp
        end
      end

      EXPECTED_IO = 60
      DEFAULT_UNIT = 'MB/sec'.freeze
      DEFAULT_DIRS = [
        '/var/lib/pulp', '/var/lib/mongodb', '/var/lib/pgsql'
      ].select { |file_path| File.directory?(file_path) }.freeze

      attr_reader :stats

      def run
        @stats = ForemanMaintain::Utils::Disk::Stats.new
        with_spinner(description) do |spinner|
          io_obj, success = compute_disk_speed(spinner)
          spinner.update('Finished')
          puts "\n"
          puts stats.stdout

          current_downstream_feature = feature(:instance).downstream
          if current_downstream_feature && current_downstream_feature.at_least_version?('6.3')
            assert(success, io_obj.slow_disk_error_msg + warning_message, :warn => true)
          else
            assert(success, io_obj.slow_disk_error_msg)
          end
        end
      end

      def check_only_single_device?
        DEFAULT_DIRS.map do |dir|
          ForemanMaintain::Utils::Disk::Device.new(dir).name
        end.uniq.length <= 1
      end

      def dirs_to_check
        return DEFAULT_DIRS.first(1) if check_only_single_device?

        DEFAULT_DIRS
      end

      private

      def warning_message
        "\nWARNING: Low disk speed might have a negative impact on the system."\
        "\nSee https://access.redhat.com/solutions/3397771 before proceeding"
      end

      def compute_disk_speed(spinner)
        success = true
        io_obj = ForemanMaintain::Utils::Disk::NilDevice.new

        dirs_to_check.each do |dir|
          io_obj = ForemanMaintain::Utils::Disk::Device.new(dir)

          spinner.update("[Speed check In-Progress] device: #{io_obj.name}")
          stats << io_obj

          next if io_obj.read_speed >= EXPECTED_IO

          success = false
          logger.info "Slow disk detected #{dir}: #{io_obj.performance}."
          break
        end

        [io_obj, success]
      end
    end
  end
end
