module Reports
  class DiskUsage < ForemanMaintain::Report
    metadata do
      label :disk_usage
      description 'Report disk consumption and availability of directories'
      preparation_steps { Procedures::Packages::Install.new(:packages => %w[hdparm fio]) }
    end

    DEFAULT_DIRS = ['/var/lib/pulp', '/var/lib/mongodb', '/var/lib/pgsql'].freeze

    attr_reader :stats

    def run
      @stats = {}
      with_spinner(description) do |spinner|
        generate_stats
        spinner.update('Finished')
        puts "\n"
        puts show_stats
      end
    end

    def to_h
      @stats = {}
      { label => generate_stats }
    end

    private

    def generate_stats
      DEFAULT_DIRS.each do |dir|
        if file_exist?(dir)
          push_stats(dir, feature(:disk).usage(dir))
        else
          push_stats(dir, 'does not exist')
        end
      end
      stats
    end

    def push_stats(dir, usage)
      stats[dir] = usage
    end

    def show_stats
      stats.map { |dir, usage| "#{dir} : #{usage}" }.join("\n")
    end
  end
end
