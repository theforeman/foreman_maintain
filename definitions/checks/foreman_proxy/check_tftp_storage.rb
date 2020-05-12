module Checks::ForemanProxy
  class CheckTftpStorage < ForemanMaintain::Check
    metadata do
      label :check_tftp_storage
      description 'Clean old Kernel and initramfs files from tftp-boot'
      tags :default
      confine do
        feature(:foreman_proxy)
      end
    end

    # rubocop:disable Metrics/MethodLength
    def run
      tftp_boot_dir = feature(:foreman_proxy).tftp_root_directory + '/boot/'
      if feature(:foreman_proxy).features.include?('tftp')
        if Dir.exist?(tftp_boot_dir)
          if token_duration != 0
            files = files_to_delete(tftp_boot_dir)
            assert(files.empty?,
                   'There are old initrd and vmlinuz files present in tftp',
                   :next_steps => Procedures::Files::Remove.new(:files => files))
          else
            skip 'Provisioning token duration is set to 0'
          end
        else
          fail! "TFTP root directory #{tftp_boot_dir} does not exist."
        end
      else
        skip 'TFTP feature is not enabled'
      end
    end
    # rubocop:enable Metrics/MethodLength

    def files_to_delete(tftp_boot_dir)
      files = list_files_in_directory(tftp_boot_dir). \
              map { |file| tftp_boot_dir + file }
      files.map do |file|
        file if File.mtime(file) + (token_duration * 60) < Time.now
      end.compact
    end

    def token_duration
      data = feature(:foreman_database). \
             query("select * from settings \
                    where category = 'Setting::Provisioning' and name = 'token_duration'")
      param = data[0]['value'].nil? ? 'default' : 'value'
      YAML.load(data[0][param])
    end
  end
end
