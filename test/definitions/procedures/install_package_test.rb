require 'test_helper'

describe Procedures::InstallPackage do
  include DefinitionsTestHelper

  subject do
    Procedures::InstallPackage.new(:packages => ['cheetah'])
  end

  context 'package is already installed' do
    specify 'necessary? returns false' do
      subject.expects(:package_version).with('cheetah').returns('1.2.3')
      refute subject.necessary?, 'install package should not be necessary'
    end
  end

  it 'installs the specified packages' do
    subject.expects(:install_packages).with(['cheetah'])
    result = run_procedure(subject)
    assert result.success?, 'the procedure was expected to succeed'
  end
end
