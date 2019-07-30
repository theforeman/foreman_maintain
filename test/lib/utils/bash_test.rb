require 'test_helper'

module ForemanMaintain
  describe Utils::Bash do
    include UnitTestHelper
    describe '#complete' do
      let(:command_map) do
        {
          'upgrade' => { :type => :flag },
          'backup' => {
            'online' => {
              '-y' => { :type => :flag },
              '--help' => { :type => :flag },
              '--verify' => { :type => :enum, :values => %w[y n] }, # TODO
              '--features' => { :type => :multienum, :values => %w[tftp dns all] }, # TODO
              '--ids' => { :type => :list }, # TODO
              '--log' => { :type => :file, :filter => '.*\.log$' },
              '--pool' => { :type => :directory },
              '-t' => { :type => :value },
              :params => [{ :type => :directory }, { :type => :value }, { :type => :file }]
            },
            '--help' => { :type => :flag },
            '--debug' => { :type => :flag }
          },
          '--help' => { :type => :flag },
          '-h' => { :type => :flag }
        }
      end

      subject do
        ForemanMaintain::Utils::Bash::Completion.new(command_map)
      end

      it 'returns options when no input given' do
        result = subject.complete('').sort
        result.must_equal ['upgrade ', 'backup ', '--help ', '-h '].sort
      end

      it 'returns filtered options when partial input is given' do
        result = subject.complete('-').sort
        result.must_equal ['--help ', '-h '].sort
      end

      it 'returns filtered options when partial input is given' do
        result = subject.complete('backup')
        result.must_equal ['backup ']
      end

      it 'returns options when subcommand is given' do
        result = subject.complete('backup ').sort
        result.must_equal ['online ', '--help ', '--debug '].sort
      end

      it 'returns no options when subcommand is wrong' do
        result = subject.complete('unknown -h')
        result.must_equal []
      end

      it 'returns no options when there are no other params allowed' do
        result = subject.complete('backup online /tmp some /tmp extra')
        result.must_equal []
      end

      it 'return hint for option-value pair without value' do
        result = subject.complete('backup online -t ')
        result.must_equal ['--->', 'Add option <value>']
      end

      it 'return no options for option-value pair without complete value' do
        result = subject.complete('backup online -t x')
        result.must_equal []
      end

      # multiple options in one subcommand
      it 'allows mutiple options of the same subcommand' do
        result = subject.complete('backup online -y --he')
        result.must_equal ['--help ']
      end

      # multiple options with values in one subcommand
      it 'allows mutiple options with values of the same subcommand' do
        result = subject.complete('backup online -t value --he')
        result.must_equal ['--help ']
      end

      # subcommand after options
      it 'allows subcommand after options' do
        result = subject.complete('backup --debug onlin')
        result.must_equal ['online ']
      end

      describe 'file and dir completion' do
        let(:data_dir) { File.join(File.dirname(__FILE__), '../../data') }

        before do
          @old_dir = Dir.pwd
          Dir.chdir(File.join(data_dir, 'completion'))
        end

        after do
          Dir.chdir(@old_dir)
        end

        # value at the cli end (backup dir)
        it 'offers parameters of dictionary type' do
          result = subject.complete('backup online ')
          result.must_include '-y '
          result.must_include '--help '
          result.must_include 'dir_a'
          result.must_include 'dir_b'
        end

        it 'offers parameters of dictionary type with completion' do
          result = subject.complete('backup online dir_').sort
          result.must_equal %w[dir_a dir_b].sort
        end

        it 'offers parameters of a file type with completion' do
          result = subject.complete('backup online dir_a val dir_').sort
          result.must_equal ['dir_a/', 'dir_b/'].sort
        end

        it 'offers options of dictionary type with completion for unfinished values' do
          result = subject.complete('backup online --pool dir_').sort
          result.must_equal %w[dir_a dir_b].sort
        end

        it 'offers options of dictionary type with completion' do
          result = subject.complete('backup online --pool ').sort
          result.must_equal %w[dir_a dir_b].sort
        end

        it 'offers options of a file type with completion for unfinished values - dir' do
          result = subject.complete('backup online --log dir_').sort
          result.must_equal ['dir_a/', 'dir_b/'].sort
        end

        it 'offers options of a file type with completion for unfinished values - file' do
          result = subject.complete('backup online --log dir_a/alpha/').sort
          result.must_equal ['dir_a/alpha/a.log ', 'dir_a/alpha/b.log '].sort
        end

        it 'offers options of a file type with completion' do
          result = subject.complete('backup online --log ').sort
          result.must_equal ['dir_a/', 'dir_b/'].sort
        end

        it 'offers parameters of dictionary type with completion, adding slash on single option' do
          result = subject.complete('backup online dir_a/a')
          result.must_equal ['dir_a/alpha/']
        end

        it 'supports multiple parameters' do
          result = subject.complete('backup online dir_a/a ')
          result.must_equal ['--->', 'Add parameter']
        end

        it 'does not complete value params' do
          result = subject.complete('backup online dir_a/a xxx')
          result.must_equal []
        end
      end
    end
  end
end
