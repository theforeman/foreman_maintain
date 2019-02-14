class Checks::YumExclude < ForemanMaintain::Check
  metadata do
    label :check_yum_exclude_list
    description 'Check if yum exclude list is configured'
    tags :pre_upgrade
  end

  def run
    assert(exclude_set?, 'The /etc/yum.conf has exclude list configured as below,'\
          "\n  #{yum_exclude}"\
          "\nUnset this as it can cause yum update or upgrade failures !")
  end

  def exclude_set?
    yum_exclude == 'exclude ='
  end

  def yum_exclude
    execute!('yum-config-manager --disableplugin=* main|grep -w exclude')
  end
end
