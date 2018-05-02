class Features::Tar < ForemanMaintain::Feature
  metadata do
    label :tar
    preparation_steps { Procedures::Packages::Install.new(:packages => %w[tar]) }
  end

  # Run system tar
  # @param [Hash] options tar configuration
  # @option options [String] :archive archive name
  # @option options [String] :command ('create') tar operation command
  # @option options [Array] :exclude dirs or files to exclude
  # @option options [String] :listed_incremental .snar file to do incremental backup
  # @option options [String] :transform sed expression to transform the filenames
  # @option options [String] :volume_size size of tar volume
  #                           (will try to split the archive when set)
  # @option options [String] :files (*) files to operate on
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def run(options = {})
    volume_size = options.fetch(:volume_size, nil)
    validate_volume_size(volume_size) unless volume_size.nil?

    tar_command = ['tar']
    tar_command << '--selinux'
    tar_command << "--#{options.fetch(:command, 'create')}"
    tar_command << "--file=#{options.fetch(:archive)}"

    if volume_size
      split_tar_script = default_split_tar_script
      tar_command << "--tape-length=#{volume_size}"
      tar_command << "--new-volume-script=#{split_tar_script}"
    end

    exclude = options.fetch(:exclude, [])
    exclude.each do |ex|
      tar_command << "--exclude=#{ex}"
    end

    snar_file = options.fetch(:listed_incremental, nil)
    tar_command << "--listed-incremental=#{snar_file}" if snar_file

    trans = options.fetch(:transform, nil)
    tar_command << "--transform '#{trans}'" if trans

    tar_command << '-S'
    tar_command << options.fetch(:files, '*')

    execute!(tar_command.join(' '))
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def validate_volume_size(size)
    if size.nil? || size !~ /^\d+[bBcGKkMPTw]?$/
      raise ForemanMaintain::Error::Validation,
            "Please specify size according to 'tar --tape-length' format."
    end
    true
  end

  private

  def default_split_tar_script
    utils_path = File.expand_path('../../../bin', __FILE__)
    split_tar_script = File.join(utils_path, 'foreman-maintain-rotate-tar')
    unless File.executable?(split_tar_script)
      raise ForemanMaintain::Error::Fail, "Script #{split_tar_script} is not executable"
    end
    split_tar_script
  end
end
