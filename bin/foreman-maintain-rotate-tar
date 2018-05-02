#!/bin/bash
## For this script it's advisable to use a shell, such as Bash,
## that supports a TAR_FD value greater than 9.

# This script taken from the tar info doc

name=`expr ${TAR_ARCHIVE} : '\(.*\)\..*'`
volnum=`printf "%04d" ${TAR_VOLUME}`
filename="${name:-$TAR_ARCHIVE}.part${volnum:-$TAR_VOLUME}"
case ${TAR_SUBCOMMAND} in
-c)       ;;
-d|-x|-t) test -r ${filename} || exit 1
          ;;
*)        exit 1
esac

echo ${filename} >&${TAR_FD}
echo " Switched to multi-volume ${filename}"
