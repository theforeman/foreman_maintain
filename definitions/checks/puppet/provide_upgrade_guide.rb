module Checks::Puppet
  class ProvideUpgradeGuide < ForemanMaintain::Check
    metadata do
      description 'Verify puppet and provide upgrade guide for it'
      tags :puppet_upgrade_guide
      confine do
        feature(:instance).downstream &&
          feature(:instance).downstream.current_minor_version == '6.3' &&
          find_package('puppet')
      end
      manual_detection
    end

    def run
      with_spinner('Verifying puppet version before upgrade') do |spinner|
        puppet_package = find_package('puppet')
        spinner.update "current puppet version: #{puppet_package}"
        curr_sat_version = feature(:instance).downstream.current_minor_version
        assert(
          (puppet_package !~ /puppet-3/),
          'Before continuing with upgrade, please make sure you finish puppet upgrade.',
          :next_steps => [
            Procedures::KnowledgeBaseArticle.new(:doc => doc_ids_by_sat_versions[curr_sat_version])
          ]
        )
      end
    end

    private

    def doc_ids_by_sat_versions
      { '6.3' => 'upgrade_puppet_guide_for_sat63' }
    end
  end
end
