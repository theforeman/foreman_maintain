require 'test_helper'

module ForemanMaintain
  describe Utils::Hammer do
    subject do
      Utils::Hammer.new
    end

    it 'executes hammer in non-interactive mode and english locale' do
      subject.expects(:execute).with(
        %(LANG=en_US.utf-8 hammer -c "#{subject.config_file}" --interactive=no task resume)
      )
      subject.run_command('task resume')
    end

    it 'executes hammer command and returns output' do
      subject.expects(:execute).returns('Tasks resumed')
      assert_equal 'Tasks resumed', subject.run_command('task resume')
    end

    it 'raises CredentialsError when the credentials are invalid' do
      subject.expects(:execute).returns('Invalid username or password')
      proc { subject.run_command('task resume') }.must_raise(Utils::Hammer::CredentialsError)
    end

    it 'provides the info about the setting of hammer via `ready?` method' do
      subject.expects(:execute).returns('Invalid username or password')
      subject.stubs(:configured?).returns(true)
      refute subject.ready?, 'hammer#ready? expected non-true'
    end
  end
end
