class Procedures::ForemanTasksResume < ForemanMaintain::Procedure
  for_feature :foreman_tasks
  description 'resume paused tasks'

  def run
    say 'resuming paused tasks'
    sleep 2
    say 'hold on'
    sleep 2
    say 'almost there'
    sleep 2
  end
end
