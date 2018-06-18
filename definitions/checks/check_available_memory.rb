class Checks::CheckAvailableMemory < ForemanMaintain::Check
  metadata do
    label :check_available_memory
    description 'Check if system has sufficient RAM available'
    tags :pre_upgrade
  end

  def run
    with_spinner('Checking if system has sufficient RAM') do
      total_ram = execute("grep MemTotal /proc/meminfo | awk '{print $2}'").to_i
      curr_feature = available_feature
      disp_mem = curr_feature.display_mem
      mem_in_gb = (curr_feature.min_mem / 1024) / 1024
      msg = "System has total #{mem_in_gb} GB RAM, at least #{disp_mem} GB RAM required."
      assert(curr_feature.min_mem < total_ram, msg)
    end
  end

  private

  def available_feature
    feature(:downstream) || feature(:katello) || feature(:upstream)
  end
end
