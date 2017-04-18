class Procedures::MissingServiceRestart < ForemanMaintain::Procedure
  metadata do
    for_feature(:missing_service)
    tags :default
    description 'restart missing service'
  end

  def run
    feature(:missing_service).restart
  end
end
