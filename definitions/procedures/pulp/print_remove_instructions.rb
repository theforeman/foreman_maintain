module Procedures::Pulp
  class PrintRemoveInstructions < ForemanMaintain::Procedure
    metadata do
      description 'Print pulp 2 removal instructions'
    end

    def run
      puts '======================================================'
      puts 'Migration of content from Pulp 2 to Pulp3 is complete'
      puts 'After verifying accessibility of content from clients,'
      puts 'it is strongly recommend to run "foreman-maintain content remove-pulp2"'
      puts 'This will remove Pulp 2, MongoDB, and all pulp2 content in /var/lib/pulp/content/'
      puts '======================================================'
    end
  end
end
