class Procedures::HammerSetup < ForemanMaintain::Procedure
  metadata do
    description 'setup hammer'
  end

  def run
    setup_from_default || setup_from_answers
    puts "New settings saved into #{hammer.config_file}"
    hammer.run_command('architecture list') # if not setup properly, an error will be risen
  end

  def necessary?
    !hammer.ready?
  end

  private

  def setup_from_default
    used_default_file = hammer.setup_from_default
    if used_default_file
      puts "Using defaults from #{used_default_file}"
      true
    end
  end

  def setup_from_answers
    loop do
      username, password = ask_for_credentials
      break if username.nil?
      if hammer.setup_from_answers(username, password)
        return true
      else
        puts 'Invalid credentials'
      end
    end
  end

  def ask_for_credentials
    username = ask('Hammer username [admin]:')
    return if username.nil?
    username = 'admin' if username.empty?
    password = ask('Hammer password:', :password => true)
    return if password.nil?
    [username.strip, password.strip]
  end

  def hammer
    ForemanMaintain::Utils::Hammer.instance
  end
end
