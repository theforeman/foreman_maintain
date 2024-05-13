class Checks::CheckIpv6Disable < ForemanMaintain::Check
  metadata do
    label :check_ipv6_disable
    description 'Check if ipv6.disable=1 is set at kernel level'
  end

  def run
    cmdline_file = File.read('/proc/cmdline')

    assert(!cmdline_file.include?("ipv6.disable=1"), error_message)
  end

  def error_message
    base = "\nThe kernel contains ipv6.disable=1 which is known to break installation and upgrade"\
           ", remove and reboot before continuining."

    if feature(:instance).downstream
      base += " See https://access.redhat.com/solutions/5045841 for more details."
    end

    base
  end
end
