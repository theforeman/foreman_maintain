module Checks::ForemanProxy
  class CheckTftpStorage < ForemanMaintain::Check
    metadata do
      label :check_tftp_storage
      description 'Clean old Kernel and initramfs files from tftp-boot'
      tags :default
      confine do
        feature(:satellite) && feature(:foreman_proxy) &&
          feature(:foreman_proxy).features.include?('tftp') && non_zero_token_duration?
      end
    end

    def run
      if Dir.exist?(tftp_boot_directory)
        files = old_files_from_tftp_boot
        assert(files.empty?,
               'There are old initrd and vmlinuz files present in tftp',
               :next_steps => Procedures::Files::Remove.new(:files => files))
      else
        skip "TFTP #{tftp_boot_directory} directory doesn't exist."
      end
    end

    def old_files_from_tftp_boot
      Dir.glob("#{tftp_boot_directory}*-{vmlinuz,initrd.img}").map do |file|
        unless File.directory?(file)
          file if File.mtime(file) + (token_duration * 60) < Time.now
        end
      end.compact
    end

    def self.non_zero_token_duration?
      lookup_token_duration != 0
    end

    def tftp_boot_directory
      @tftp_boot_directory ||= "#{feature(:foreman_proxy).tftp_root_directory}/boot/"
    end

    def token_duration
      @token_duration ||= self.class.lookup_token_duration
    end

    def self.lookup_token_duration
      data = feature(:foreman_database). \
             query("select s.value, s.default from settings s \
                    where category = 'Setting::Provisioning' and name = 'token_duration'")
      YAML.load(data[0]['value'] || data[0]['default'])
    end
  end
end
