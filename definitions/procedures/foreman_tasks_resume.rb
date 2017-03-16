class Procedures::ForemanTasksResume < ForemanMaintain::Procedure
  metadata do
    for_feature :foreman_tasks
    description 'resume paused tasks'
  end

  def run
    with_spinner('resuming paused tasks') do |spinner|
      sleep 1
      spinner.update 'hold on'
      sleep 1
      spinner.update 'almost there'
      sleep 1
      spinner.update 'finished'
    end
  end
end
