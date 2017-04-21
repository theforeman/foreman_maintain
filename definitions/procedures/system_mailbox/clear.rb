module Procedures::SystemMailbox
  class Clear < ForemanMaintain::Procedure
    metadata do
      description "clear root's mailbox"
      param :file_path
      advanced_run false
    end

    attr_reader :file_path

    def run
      with_spinner('clearing all existing mails') do
        execute("cat /dev/null > #{file_path}")
      end
    end
  end
end
