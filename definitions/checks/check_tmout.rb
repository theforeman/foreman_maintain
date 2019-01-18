class Checks::CheckTmout < ForemanMaintain::Check
  metadata do
    label :check_tmout_variable
    description 'Check if TMOUT environment variable is set'
    tags :pre_upgrade
  end

  def run
    assert(tmout_unset?, "The TMOUT environment variable is set with value #{tmout_env}."\
          " Run 'unset TMOUT' command to unset this variable.")
  end

  def tmout_unset?
    tmout_env == '0' || tmout_env == '' || tmout_env.nil?
  end

  def tmout_env
    ENV['TMOUT']
  end
end
