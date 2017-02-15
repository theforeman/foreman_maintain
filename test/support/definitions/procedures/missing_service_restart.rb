class Procedures::MissingServiceRestart < ForemanMaintain::Procedure
  for_feature(:missing_service)
  tags :basic
  description 'restart missing service'

  def run
    feature(:missing_service).restart
  end
end
