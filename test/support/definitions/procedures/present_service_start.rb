class Procedures::PresentServiceStart < ForemanMaintain::Procedure
  for_feature(:present_service)
  tags :start
  description 'start the present service'

  def run
    feature(:present_service).start
  end
end
