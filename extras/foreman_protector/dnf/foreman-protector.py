import configparser
import os

import dnf
import dnf.exceptions
from dnfpluginscore import _, logger


PROTECT_COMMANDS = ('install', 'downgrade', 'reinstall', 'distro-sync', 'swap', 'upgrade', 'upgrade-minimal')

class ForemanProtector(dnf.Plugin):
    name = 'foreman-protector'
    config_name = 'foreman-protector'

    def _get_whitelist_file_url(self):
        try:
             parser = self.read_config(self.base.conf)
        except Exception as e:
            raise dnf.exceptions.Error(_("Parsing file failed: {}").format(str(e)))

        if parser.has_section('main'):
            fileurl = parser.get('main', 'whitelist')
        else:
            raise dnf.exceptions.Error(_('Incorrect plugin configuration!'))
        return fileurl

    def _load_whitelist(self):
        fileurl = self._get_whitelist_file_url()
        package_whitelist = set()
        try:
            if fileurl:
                llfile = open(fileurl, 'r')
                for line in llfile.readlines():
                    if line.startswith('#') or line.strip() == '':
                        continue

                    package_whitelist.add(line.rstrip())
                llfile.close()
        except IOError as e:
            raise dnf.exceptions.Error('Unable to read Foreman protector"s configuration: %s' % e)
        return package_whitelist

    def _add_obsoletes(self):
        package_whitelist = self._load_whitelist()
        final_query = self.base.sack.query()
        if package_whitelist:
        #  If anything obsoletes something that we have whitelisted ... then
        # whitelist that too.
            whitelist_query = self.base.sack.query().filterm(name=package_whitelist)
            obsoletes_query = self.base.sack.query().filterm(obsoletes=list(whitelist_query))

            final_query = whitelist_query.union(obsoletes_query)
        return final_query

    def sack(self):
        if self.cli is not None and self.cli.command is not None and self.cli.command._basecmd not in PROTECT_COMMANDS:
            return
        if os.environ.get('LEAPP_IPU_IN_PROGRESS') is not None:
            return
        whitelist_and_obsoletes = self._add_obsoletes()
        all_available_packages = self.base.sack.query().available()
        excluded_pkgs_query = all_available_packages.difference(whitelist_and_obsoletes)
        total = len(excluded_pkgs_query)
        logger.info(_('Reading Foreman protector configuration'))
        self.base.sack.add_excludes(excluded_pkgs_query)

        logger.info(_('*** Excluded total: %s' % total))
        if total:
            if total > 1:
                suffix = 's'
            else:
                suffix = ''
            logger.info(_('\n'
                            'WARNING: Excluding %d package%s due to foreman-protector. \n'
                            'Use foreman-maintain packages install/update <package> \n'
                            'to safely install packages without restrictions.\n'
                            'Use foreman-maintain upgrade run for full upgrade.\n'
                            % (total, suffix)))
        else:
            logger.info(_('\n'
                            'Nothing excluded by foreman-protector!\n'))
