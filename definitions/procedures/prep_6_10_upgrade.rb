class Procedures::Prep610Upgrade < ForemanMaintain::Procedure
  metadata do
    description 'Preparations for the Satellite 6.10 upgrade'

    confine do
      feature(:satellite) &&
        feature(:satellite).current_minor_version == '6.9'
    end
  end

  def run
    puts time_warning
    with_spinner('Updating filesystem permissions for Pulp 3') do |spinner|
      spinner.update('# chmod -R g+rwX /var/lib/pulp/content')
      FileUtils.chmod_R 'g=rwX', '/var/lib/pulp/content'
      spinner.update("# find /var/lib/pulp/content -type d -perm -g-s -exec chmod g+s {} \;")
      execute!('find /var/lib/pulp/content -type d -perm -g-s -exec chmod g+s {} \;')
      spinner.update('# chgrp -R pulp /var/lib/pulp/content')
      FileUtils.chown_R nil, 'pulp', '/var/lib/pulp/content'
    end
  end

  private

  def time_warning
    "\e[33mprep-6.10-upgrade may take a while depending on the "\
    "size of /var/lib/pulp/content\e[0m"
  end
end
