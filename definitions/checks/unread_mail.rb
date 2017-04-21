class Checks::UnreadMail < ForemanMaintain::Check
  metadata do
    label :unread_mail
    description "Check for mails in root's mailbox."
    tags :unread_mail
  end

  def run
    file_path = root_mail_file_path
    if file_exists?(file_path)
      mcount = mails_count(file_path)
      assert(mcount == 0, "WARNING: Found #{mcount} mail(s) in root's mailbox.",
             :next_steps => [Procedures::SystemMailbox::List.new(:file_path => file_path),
                             Procedures::SystemMailbox::Clear.new(:file_path => file_path)],
             :error_type => ForemanMaintain::Error::Warn)
    end
  end

  private

  def root_mail_file_path
    mailbox_dir = find_mailbox_directory
    "#{mailbox_dir}/root"
  end

  def find_mailbox_directory
    dir = '/var/spool/mail'
    config_file_to_check = '/etc/login.defs'
    if file_exists?(config_file_to_check)
      cmd = "grep ^MAIL_DIR #{config_file_to_check} | awk '{ print $2}'"
      output = execute(cmd).strip
      dir = output unless output.empty?
    end
    dir
  end

  def mails_count(file_path)
    cmd = "egrep -c '^Message-Id' #{file_path}"
    execute(cmd).to_i
  end
end
