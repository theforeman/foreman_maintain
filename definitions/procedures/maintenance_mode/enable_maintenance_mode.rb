module Procedures::MaintenanceMode
  class EnableMaintenanceMode < ForemanMaintain::Procedure
    metadata do
      label :enable_maintenance_mode
      description 'Add maintenance_mode tables/chain to nftables/iptables'
      tags :pre_migrations, :maintenance_mode_on
      after :sync_plans_disable
    end

    def run
      if feature(:instance).firewall
        feature(:instance).firewall.enable_maintenance_mode
      else
        notify_and_ask_to_install_firewall_utility
      end
    end

    def notify_and_ask_to_install_firewall_utility
      puts 'Unable to find nftables or iptables!'
      question, pkg = question_and_pkg_name
      answer = ask_decision(question, actions_msg: 'y(yes), q(quit)')
      if answer == :yes
        packages_action(:install, pkg)
        feature(:instance).firewall.enable_maintenance_mode
      end
    end

    def can_install_nft?
      nft_kernel_version = Gem::Version.new('3.13')
      installed_kernel_version = Gem::Version.new(execute!('uname -r').split('-').first)
      installed_kernel_version >= nft_kernel_version
    end

    def question_and_pkg_name
      question = 'Do you want to install missing netfilter utility '
      pkg_to_install = []
      if can_install_nft?
        question << 'nftables?'
        pkg_to_install << 'nftables'
      else
        question << 'iptables?'
        pkg_to_install << 'iptables'
      end
      question << "\nand start maintenance mode?"
      [question, pkg_to_install]
    end
  end
end
