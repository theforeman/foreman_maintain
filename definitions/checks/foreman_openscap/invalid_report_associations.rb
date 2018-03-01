module Checks
  module ForemanOpenscap
    class InvalidReportAssociations < ForemanMaintain::Check
      metadata do
        label :openscap_report_associations
        for_feature :foreman_openscap
        description 'Check whether reports have correct associations'
        tags :pre_upgrade, :foreman_openscap, :openscap_report_associations
      end

      def run
        ids_to_remove = to_remove
        assert(ids_to_remove.empty?,
               "There are #{ids_to_remove.count} reports with issues that will be removed",
               :next_steps => Procedures::ForemanOpenscap::InvalidReportAssociations.new(
                 :ids_to_remove => ids_to_remove
               ))
      end

      def to_remove
        (feature(:foreman_openscap).report_ids_without_policy +
         feature(:foreman_openscap).report_ids_without_proxy +
         feature(:foreman_openscap).report_ids_without_host).uniq
      end
    end
  end
end
