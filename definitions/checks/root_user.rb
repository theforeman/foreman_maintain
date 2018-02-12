class Checks::RootUser < ForemanMaintain::Check
  metadata do
    label :root_user
    tags :root_user
    description 'Check if command is run as root user'
  end

  def run
    is_root_user = Process.uid == 0
    assert(is_root_user, 'This command needs to be run as the root user')
  end
end
