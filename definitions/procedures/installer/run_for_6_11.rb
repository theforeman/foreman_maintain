module Procedures::Installer
  class RunFor6_11 < ForemanMaintain::Procedure
    metadata do
      description 'Run installer with Candlepin SSL CA'\
                  ' when using external database with SSL'
      param :assumeyes, 'Do not ask for confirmation'
      manual_detection
    end

    def run
      if extdb_and_ssl?
        run_installer_with_extra_option
      else
        run_installer
      end
    end

    def ext_db?
      !feature(:foreman_database).local?
    end

    def installer_answers
      @installer_answers ||= feature(:installer).answers
    end

    def server_db_with_ssl?
      installer_answers.fetch('katello')['candlepin_db_ssl']
    end

    def extdb_and_ssl?
      ext_db? && server_db_with_ssl?
    end

    def run_installer_with_extra_option
      ssl_ca_path = installer_answers.fetch('foreman')['db_root_cert']
      spinner_msg = "Running installer with --katello-candlepin-db-ssl-ca #{ssl_ca_path} argument!"
      with_spinner(spinner_msg) do
        installer_args = feature(:installer).installer_arguments
        new_ssl_arg = " --katello-candlepin-db-ssl-ca #{ssl_ca_path}"
        installer_args << new_ssl_arg
        feature(:installer).run(installer_args)
      end
    end

    def run_installer
      with_spinner('Executing installer') do
        assumeyes_val = @assumeyes.nil? ? assumeyes? : @assumeyes
        feature(:installer).upgrade(:interactive => !assumeyes_val)
      end
    end
  end
end
