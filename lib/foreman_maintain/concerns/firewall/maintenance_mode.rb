module ForemanMaintain
  module Concerns
    module Firewall
      module MaintenanceMode
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
          # The nftables is default from EL8 and Debian 10(Buster)
          (el? && el_major_version >= 8) ||
            (debian? && deb_major_version >= 10) ||
            (ubuntu? && ubuntu_major_version.to_i >= 22)
        end

        def question_and_pkg_name
          pkg_to_install = can_install_nft? ? 'nftables' : 'iptables'
          question = "Do you want to install missing netfilter utility #{pkg_to_install}?"\
                     "\nand start maintenance mode?"
          [question, [pkg_to_install]]
        end
      end
    end
  end
end
