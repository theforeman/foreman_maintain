class Checks::YumExclude < ForemanMaintain::Check
  metadata do
    label :check_yum_exclude_list
    description 'Check if yum exclude list is configured'
    tags :pre_upgrade
  end

  def run
    assert(!exclude_set?, 'The /etc/yum.conf has exclude list configured as below,'\
          "\n  #{grep_yum_exclude[1]}"\
          "\nUnset this as it can cause yum update or upgrade failures !")
  end

  def exclude_set?
    return true if grep_yum_exclude[1] =~ /^exclude\s*=\s*\S+/

    false
  end

  def grep_yum_exclude
    execute_with_status('grep -w exclude /etc/yum.conf')
  end
end
