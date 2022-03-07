from yum.plugins import PluginYumExit
from yum.plugins import TYPE_CORE
from rpmUtils.miscutils import splitFilename
from yum.packageSack import packagesNewestByName

import urlgrabber
import urlgrabber.grabber

import os
import fnmatch
import tempfile
import time

requires_api_version = '2.1'
plugin_type = (TYPE_CORE,)

_package_whitelist = set()
fileurl = None

def _load_whitelist():
    try:
      if fileurl:
        llfile = urlgrabber.urlopen(fileurl)
        for line in llfile.readlines():
            if line.startswith('#') or line.strip() == '':
                continue
            _package_whitelist.add(line.rstrip().lower())
        llfile.close()
    except urlgrabber.grabber.URLGrabError as e:
        raise PluginYumExit('Unable to read Foreman protector"s configuration: %s' % e)

def _add_obsoletes(conduit):
    if _package_whitelist:
        #  If anything obsoletes something that we have whitelisted ... then
        # whitelist that too.
        for (pkgtup, instTup) in conduit._base.up.getObsoletesTuples():
            if instTup[0] not in _package_whitelist:
                continue
            _package_whitelist.add(pkgtup[0].lower())

def _get_updates(base):
    updates = {}

    for p in base.pkgSack.returnNewestByName():
        if p.name in _package_whitelist:
            # This one is whitelisted, skip
            continue
        updates[p.name] = p

    return updates

def config_hook(conduit):
    global fileurl

    fileurl = conduit.confString('main', 'whitelist')

def _add_package_whitelist_excluders(conduit):
    if hasattr(conduit, 'registerPackageName'):
        conduit.registerPackageName("yum-plugin-foreman-protector")
    ape = conduit._base.pkgSack.addPackageExcluder
    exid = 'foreman-protector.W.'
    ape(None, exid + str(1), 'mark.washed')
    ape(None, exid + str(2), 'wash.name.in', _package_whitelist)
    ape(None, exid + str(3), 'exclude.marked')

def exclude_hook(conduit):
    conduit.info(3, 'Reading Foreman protector configuration')

    _load_whitelist()
    _add_obsoletes(conduit)

    total = len(_get_updates(conduit._base))
    conduit.info(3, '*** Excluded total: %s' % total)
    if total:
        if total > 1:
            suffix = 's'
        else:
            suffix = ''
        conduit.info(1, '\n'
                        'WARNING: Excluding %d package%s due to foreman-protector. \n'
                        'Use foreman-maintain packages install/update <package> \n'
                        'to safely install packages without restrictions.\n'
                        'Use foreman-maintain upgrade run for full upgrade.\n'
                        % (total, suffix))

    _add_package_whitelist_excluders(conduit)
