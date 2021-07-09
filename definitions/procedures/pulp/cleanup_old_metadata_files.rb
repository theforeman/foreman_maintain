require 'find'
require 'nokogiri'

module Procedures::Pulp
  class CleanupOldMetadataFiles < ForemanMaintain::Procedure
    metadata do
      description 'Cleanup old and unneeded yum metadata files from /var/lib/pulp/'
      confine do
        check_max_version('katello-common', '4.0')
      end
      param :remove_files, 'If true, will actually delete files, otherwise will print them out.'
    end

    PULP_METADATA_DIR = '/var/lib/pulp/published/yum/master/yum_distributor/'.freeze
    REPOMD_FILE = 'repomd.xml'.freeze

    def run
      return unless File.directory?(PULP_METADATA_DIR)
      puts 'Locating repository metadata (this may take a while):'
      found = []
      Find.find(PULP_METADATA_DIR) do |path|
        next if File.basename(path) != REPOMD_FILE
        found << path
        print '.'
        $stdout.flush
      end

      puts "Found #{found.length} repositories to scan."
      found.each do |repo_md_path|
        handle(repo_md_path, @remove_files)
      end
    end

    def handle(repo_md_path, remove_files)
      base_path = File.dirname(repo_md_path)
      to_remove = list_existing_files(repo_md_path) - list_repomd_files(repo_md_path)

      if to_remove.empty?
        "Skipping #{base_path}, no files to remove."
      elsif remove_files
        puts "Removing #{to_remove.count} files from #{base_path}"
        to_remove.each { |file| File.delete(File.join(base_path, file)) }
      else
        puts '============================================='
        puts "For #{base_path} would remove, but --remove-files was not specified:"
        to_remove.each { |file| puts "   #{file}" }
      end
    end

    def list_repomd_files(repo_md_path)
      content = File.read(repo_md_path)
      doc = Nokogiri::XML(content)
      filenames = doc.css('location').map { |e| e.attributes['href'].value }
      base_names(filenames)
    end

    def list_existing_files(repo_md_path)
      base_names(Dir[File.dirname(repo_md_path) + '/*']) - [REPOMD_FILE]
    end

    def base_names(file_list)
      file_list.map { |file| File.basename(file) }
    end
  end
end
