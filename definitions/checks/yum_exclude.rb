class Checks::YumExclude < ForemanMaintain::Check
  metadata do
    label :check_yum_exclude_list
    description 'Check if yum exclude list is configured'
    tags :pre_upgrade
  end

  EXCLUDE_SET_RE = /^exclude\s*=\s*\S+.*$/.freeze

  def run
    grep_result = grep_yum_exclude
    assert(!grep_result.match(EXCLUDE_SET_RE),
           'The /etc/yum.conf has exclude list configured as below,'\
          "\n  #{grep_result}"\
          "\nUnset this as it can cause yum update or upgrade failures !")
  end

  def grep_yum_exclude
    execute_with_status('grep -w exclude /etc/yum.conf')[1]
  end
end
