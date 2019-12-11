module Procedures::ForemanOpenscap
  class InvalidReportAssociations < ForemanMaintain::Procedure
    metadata do
      param :ids_to_remove, 'Ids of reports to remove', :required => true
      for_feature :foreman_openscap
      tags :foreman_openscap, :openscap_report_associations
      advanced_run false
      description 'Delete reports with association issues'
    end

    def run
      feature(:foreman_openscap).delete_reports(@ids_to_remove)
    end
  end
end
