module Procedures::Puppet
  class DeleteEmptyCaCertRequestFiles < ForemanMaintain::Procedure
    metadata do
      description 'Delete empty CA cert request files'
      confine do
        feature(:puppet_server)
      end
    end

    def run
      cacert_dir_path = feature(:puppet_server).cacert_requests_directory
      if feature(:puppet_server).cacert_requests_dir_exists?
        files = feature(:puppet_server).find_empty_cacert_request_files
        if files.empty?
          puts "No empty file(s) under #{cacert_dir_path}"
        else
          print_files_details(files, cacert_dir_path)
          with_spinner('Deleting empty CA cert request files') do |spinner|
            feature(:puppet_server).delete_empty_cacert_files
            spinner.update 'Done with deleting empty cert request files'
          end
        end
      else
        skip "#{cacert_dir_path} directory not found"
      end
    end

    private

    def print_files_details(files, cacert_dir_path)
      puts "Empty CA cert file(s) under #{cacert_dir_path}:"
      files.each_with_index do |file_name, index|
        puts "#{index + 1}. #{file_name}"
      end
    end
  end
end
