class Procedures::ForemanTasksResume < ForemanMaintain::Procedure
  for_feature :foreman_tasks
  description 'resume paused tasks'

  def run
    say 'resuming paused tasks'
    sleep 1
    say 'hold on'
    sleep 1
    say 'almost there'
    sleep 1
  end
end
