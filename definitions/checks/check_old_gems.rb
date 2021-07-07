class Checks::CheckOldGems < ForemanMaintain::Check
  metadata do
    label :check_old_gems
    description 'Check if any old gem directory is present'
    tags :post_upgrade
    confine do
      feature(:instance).downstream
    end
  end

  def run
    files = old_gem_directories
    assert(files.empty?,
           "There are few old ruby gem directories present on the system. \n #{files.join('\n')} ",
           :next_steps => Procedures::Files::Remove.new(:files => files))
  end

  def old_gem_directories
    gems_home_directory = '/opt/theforeman/tfm/root/usr/share/gems/gems'
    cmd = "rpm -qf #{gems_home_directory}/* | grep -i 'not owned by any package' | awk '{print $2}'"
    execute(cmd).split("\n")
  end
end
