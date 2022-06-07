module Procedures::Installer
  class RunFor6_11 < ForemanMaintain::Procedure
    metadata do
      description 'Ask for Candlepin Database SSL CA certificate'\
                  'to run installer in post upgrade'
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

    def server_db_with_ssl?
      answers = feature(:installer).answers
      db_sslmode = answers.fetch('foreman')['db_sslmode']
      db_sslmode == 'verify-full'
    end

    def extdb_and_ssl?
      ext_db? && server_db_with_ssl?
    end

    def ask_for_ca_path
      msg = 'The system is using external database over SSL protocol!'\
			      "\nThe Satellite 6.11 has introduced new installer flag"\
			      "\n--katello-candlepin-db-ssl-ca which is required to proceed further."\
			      "\nRequest to provide path of Candlepin DB SSL CA:"
      ask(msg)
    end

    def run_installer_with_extra_option
      ssl_ca_path = ask_for_ca_path
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
