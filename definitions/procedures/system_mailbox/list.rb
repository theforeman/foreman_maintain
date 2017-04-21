module Procedures::SystemMailbox
  class List < ForemanMaintain::Procedure
    metadata do
      description "list mails from root's mailbox"
      param :file_path
      advanced_run false
    end

    attr_reader :file_path

    def run
      puts(<<-MESSAGE.strip_heredoc)
        file content #{file_path} :=>
        #{execute("cat #{file_path}")}
      MESSAGE
    end
  end
end
