class Checks::DiskSpeedMinimal < ForemanMaintain::Check
  metadata do
    label :disk_io
    description 'Check for recommended disk speed of pulp, mongodb, pgsql dir.'
    tags :basic

    confine do
      execute?('which hdparm') && execute?('which fio')
    end
  end

  EXPECTED_IO = 80
  DEFAULT_UNIT   = 'MB/sec'.freeze
  DEFAULT_DIRS   = ['/var/lib/pulp', '/var/lib/mongodb', '/var/lib/pgsql'].freeze

  def run
    success = true
    io_obj = ForemanMaintain::Utils::Disk::NilDevice.new

    dirs_to_check.each do |dir|
      io_obj = ForemanMaintain::Utils::Disk::Device.new(dir)

      next if io_obj.read_speed >= EXPECTED_IO

      success = false
      logger.info "Slow disk detected #{dir}: #{io_obj.read_speed} #{io_obj.unit}."
      break
    end

    assert(success, io_obj.slow_disk_error_msg)
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
end
