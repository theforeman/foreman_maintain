class Checks::CheckTmout < ForemanMaintain::Check
  metadata do
    label :check_tmout_variable
    description 'Check if TMOUT environment variable is set'
    tags :pre_upgrade
  end

  def run
    assert(tmout_set?, 'The TMOUT environment variable is set on system.'\
          " Run 'unset TMOUT' command to unset this variable.")
  end

  def tmout_set?
    execute('printenv TMOUT').empty?
  end
end
