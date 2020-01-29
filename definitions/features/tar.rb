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
  # @option options [String] :directory change to directory DIR
  # @option options [Boolean] :multi_volume create/list/extract multi-volume archive
  # @option options [Boolean] :overwrite overwrite existing files when extracting
  # @option options [Boolean] :gzip filter the archive through gzip
  # @option options [Boolean] :ignore_failed_read do not fail on missing files
  # @option options [Boolean] :allow_changing_files do not fail on changing files
  def run(options = {})
    logger.debug("Invoking tar from #{options[:directory] || FileUtils.pwd}")
    statuses = options[:allow_changing_files] ? [0, 1] : [0]
    execute!(tar_command(options), :valid_exit_statuses => statuses)
  end

  def validate_volume_size(size)
    if size.nil? || size !~ /^\d+[bBcGKkMPTw]?$/
      raise ForemanMaintain::Error::Validation,
            "Please specify size according to 'tar --tape-length' format."
    end
    true
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def tar_command(options)
    volume_size = options.fetch(:volume_size, nil)
    absolute_names = options.fetch(:absolute_names, nil)
    validate_volume_size(volume_size) unless volume_size.nil?

    tar_command = ['tar']
    tar_command << '--selinux'
    tar_command << "--#{options.fetch(:command, 'create')}"
    tar_command << "--file=#{options.fetch(:archive)}"

    if absolute_names
      tar_command << '--absolute-names'
    end

    if volume_size
      split_tar_script = default_split_tar_script
      tar_command << "--tape-length=#{volume_size}"
      tar_command << "--new-volume-script=#{split_tar_script}"
    end

    tar_command << '--overwrite' if options[:overwrite]
    tar_command << '--gzip' if options[:gzip]

    exclude = options.fetch(:exclude, [])
    exclude.each do |ex|
      tar_command << "--exclude=#{ex}"
    end

    snar_file = options.fetch(:listed_incremental, nil)
    tar_command << "--listed-incremental=#{snar_file}" if snar_file

    trans = options.fetch(:transform, nil)
    tar_command << "--transform '#{trans}'" if trans

    tar_command << '-M' if options[:multi_volume]
    tar_command << "--directory=#{options[:directory]}" if options[:directory]

    tar_command << '--ignore-failed-read' if options[:ignore_failed_read]

    if options[:files]
      tar_command << '-S'
      tar_command << options.fetch(:files, '*')
    end

    tar_command.join(' ')
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  private

  def default_split_tar_script
    utils_path = File.expand_path('../../bin', __dir__)
    split_tar_script = File.join(utils_path, 'foreman-maintain-rotate-tar')
    unless File.executable?(split_tar_script)
      raise ForemanMaintain::Error::Fail, "Script #{split_tar_script} is not executable"
    end

    split_tar_script
  end
end
