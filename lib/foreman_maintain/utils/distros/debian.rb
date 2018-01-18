module ForemanMaintain
  module Utils
    class Distros
      class Debian < Distros
        def code_name
          @code_name ||= execute!('lsb_release -sc')
        end

        def setup_repositories
          if source_list_file
            update_source_list_file
            upgrade_foreman_package
          else
            raise Error::Fail,
                  "Manifest file not found. Please follow upgrade instructions #{upgrade_docs}"
          end
        end

        private

        def create_update_foreman_source_list
          execute!(
            "printf '#{foreman_deb_mirror}\n#{foreman_deb_mirror('plugins')}\n' > "\
            '/etc/apt/sources.list.d/foreman.list'
          )
        end

        def foreman_deb_mirror(plugins = nil)
          "deb http://deb.theforeman.org/ #{plugins || code_name} #{upgrade_version}"
        end

        def upgrade_foreman_package
          execute!(%(apt-get update))
          execute!(%(apt-get --only-upgrade install ruby\* foreman\*))
        end

        def source_list_file
          @source_list_file ||=
            execute(%(grep -m1 -H -R "deb.theforeman.org" /etc/apt/ | cut -d: -f1))
        end

        def update_source_list_file
          remove_foreman_master_source_list
          create_update_foreman_source_list
        end

        def remove_foreman_master_source_list
          execute!("sed -i.bkp '/deb.theforeman.org/d' /etc/apt/sources.list")
        end

        def upgrade_docs
          "https://www.theforeman.org/manuals/#{upgrade_version}/index.html#3.6Upgrade"
        end
      end
    end
  end
end
