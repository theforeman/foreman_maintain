class Procedures::HammerSetup < ForemanMaintain::Procedure
  def run
    return if hammer.setup_from_default
    loop do
      username, password = ask_for_credentials
      break if username.nil?
      if hammer.setup_from_answers(username, password)
        break
      else
        puts 'Invalid credentials '
      end
    end
    hammer.run_command('architecture list') # if not setup properly, an error will be risen
  end

  def necessary?
    !hammer.ready?
  end

  def description
    'Setup hammer'
  end

  private

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
