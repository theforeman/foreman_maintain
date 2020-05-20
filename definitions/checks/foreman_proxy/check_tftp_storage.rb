module Checks::ForemanProxy
  class CheckTftpStorage < ForemanMaintain::Check
    metadata do
      label :check_tftp_storage
      description 'Clean old Kernel and initramfs files from tftp-boot'
      tags :default
      confine do
        feature(:satellite)
      end
    end

    def run
      tftp_boot_dir = feature(:foreman_proxy).tftp_root_directory + '/boot/'
      if !feature(:foreman_proxy).features.include?('tftp') || token_duration == 0
        skip 'Skipping the check as TFTP feature is disabled or token duration is zero'
      elsif Dir.exist?(tftp_boot_dir)
        files = files_to_delete(tftp_boot_dir)
        assert(files.empty?,
               'There are old initrd and vmlinuz files present in tftp',
               :next_steps => Procedures::Files::Remove.new(:files => files))
      else
        warn! "TFTP root directory #{tftp_boot_dir} does not exist."
      end
    end

    def files_to_delete(tftp_boot_dir)
      list_files_in_directory(tftp_boot_dir).map do |file|
        tftp_boot_dir + file if File.mtime(tftp_boot_dir + file) + (token_duration * 60) < Time.now
      end.compact
    end

    def token_duration
      @token_duration ||= lookup_token_duration
    end

    def lookup_token_duration
      data = feature(:foreman_database). \
             query("select * from settings \
                    where category = 'Setting::Provisioning' and name = 'token_duration'")
      YAML.load(data[0]['value'] || data[0]['default'])
    end
  end
end
