class Procedures::PresentServiceStart < ForemanMaintain::Procedure
  metadata do
    for_feature(:present_service)
    tags :start
    description 'start the present service'
  end

  def run
    feature(:present_service).start
  end
end
