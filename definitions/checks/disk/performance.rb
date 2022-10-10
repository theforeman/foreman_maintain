module Checks
  module Disk
    class Performance < ForemanMaintain::Check
      metadata do
        label :disk_performance
        preparation_steps do
          if feature(:instance).downstream
            [Checks::Repositories::CheckNonRhRepository.new,
             Procedures::Packages::Install.new(:packages => %w[fio])]
          else
            [Procedures::Packages::Install.new(:packages => %w[fio])]
          end
        end

        confine do
          feature(:instance).pulp
        end
      end

      EXPECTED_IO = 60
      DEFAULT_UNIT = 'MB/sec'.freeze

      attr_reader :stats

      def run
        @stats = ForemanMaintain::Utils::Disk::Stats.new
        with_spinner(description) do |spinner|
          io_obj, success = compute_disk_speed(spinner)
          spinner.update('Finished')
          puts "\n"
          puts stats.stdout

          current_downstream_feature = feature(:instance).downstream
          if current_downstream_feature&.at_least_version?('6.3')
            assert(success, io_obj.slow_disk_error_msg + warning_message, :warn => true)
          else
            assert(success, io_obj.slow_disk_error_msg)
          end
        end
      end

      def data_dirs
        @data_dirs ||= %i[pulpcore_database mongo foreman_database].inject({}) do |dirs, f|
          if feature(f) && File.directory?(feature(f).data_dir)
            dirs[feature(f).label_dashed] = feature(f).data_dir
          end
          dirs
        end
      end

      def pulp_dir
        @pulp_dir ||= begin
          pulp_feature = feature(:pulp2) || feature(:pulpcore_database)
          { pulp_feature.label_dashed => pulp_feature.pulp_data_dir }
        end
      end

      def description
        'Check recommended disk speed for '\
        "#{[data_dirs.keys | pulp_dir.keys].join(', ')} directories."
      end

      def all_dirs
        data_dirs.values | pulp_dir.values
      end

      def check_only_single_device?
        all_dirs.each do |dir|
          ForemanMaintain::Utils::Disk::Device.new(dir).name
        end.uniq.length <= 1
      end

      def dirs_to_check
        return all_dirs.first(1) if check_only_single_device?

        all_dirs
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

          spinner.update("[Speed check In-Progress] device:#{io_obj.name}")
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
