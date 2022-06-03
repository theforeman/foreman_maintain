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
          el_major_version >= 8 || deb_major_version >= 10
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
  end
end
