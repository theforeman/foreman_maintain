class Features::Katello < ForemanMaintain::Feature
  metadata do
    label :katello

    confine do
      find_package('katello')
    end
  end

  def data_dirs
    @dirs ||= ['/var/lib/pulp', '/var/lib/mongodb', '/var/lib/pgsql']
  end

  def current_version
    @current_version ||= rpm_version('katello')
  end
end
