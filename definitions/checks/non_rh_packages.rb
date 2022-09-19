class Checks::NonRhPackages < ForemanMaintain::Check
  metadata do
    label :non_rh_packages
    description 'Check if system has any non Red Hat RPMs installed (e.g.: Fedora)'
    tags :pre_upgrade
    confine do
      feature(:instance).downstream
    end
  end

  def run
    rpm_query_format = '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH} : %{VENDOR}\n'
    all_packages = package_manager.list_installed_packages(rpm_query_format)
    non_rh_packages = all_packages - all_packages.grep(Regexp.union(rh_regexp_list))
    assert(non_rh_packages.empty?, error_msg(non_rh_packages), :warn => true)
  end

  def error_msg(packages)
    "Found #{packages.count} unexpected non Red Hat Package(s) installed!\
    \nPackage : Vendor\n#{packages.join("\n")}"
  end

  def rh_regexp_list
    [/Red Hat, Inc\./, /Red Hat Inc./, /-apache/, /-foreman-proxy/, /-foreman-client/,
     /-puppet-client/, /-qpid-broker/, /-qpid-client-cert/, /-qpid-router-client/,
     /-qpid-router-server/, /java-client/, /pulp-client/, /katello-default-ca/, /katello-server-ca/,
     /katello-ca-consumer/, /gpg-pubkey/, /-tomcat/]
  end
end
