class Procedures::CapsulePulpClear < ForemanMaintain::Procedure
  def run
    if File.directory?('/var/lib/pulp/content')
    `rm -rf /var/lib/pulp/content/*`
    `katello-service stop`
    `mongo pulp_database --eval 'db.repo_importers.update({"scratchpad": {$ne: null}}, {$set: {"scratchpad.repomd_revision": null}}, {"multi":true})'`
    `katello-service-start`
    logger.info 'Pulp content successfully removed.'
    else
    logger.warn 'Pulp content directory not present at \'/var/lib/pulp/content\''
    end
  end
end
