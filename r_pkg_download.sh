#! /bin/bash

# change here #
PKG_DIR="${HOME}/r_pkg"
REQUIRED_PKG=("ggrepel" "gtools" "doParallel")
###############

set -eu
CWD=$PWD
SCRIPT_DIR=${0%/*}
REQUIRED_PKG_STR=$( IFS=$' '; echo "${REQUIRED_PKG[*]}" )

mkdir -p ${PKG_DIR}
cd ${PKG_DIR}
# download stringi (NO-INTERNET version)
# see https://github.com/gagolews/stringi/blob/master/INSTALL

# check machine
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac

if $machine != Mac; then
  SED="sed"
else
  SED="gsed"
fi

# check download command
if hash wget 2>/dev/null; then
  DOWNLOAD="wget"
  OUTPUT_FLAG="-O"
else
  DOWNLOAD="curl -L"
  OUTPUT_FLAG="-o"
fi

# download stringi
${DOWNLOAD} https://github.com/gagolews/stringi/archive/master.zip ${OUTPUT_FLAG} stringi.zip
unzip stringi.zip
${SED} -i '/\/icu..\/data/d' stringi-master/.Rbuildignore
R CMD build stringi-master
rm stringi.zip
rm stringi-master -rf

Rscript --slave --vanilla ${SCRIPT_DIR}/r_pkg_download.R ${REQUIRED_PKG_STR}

cd ${CWD}
tar cf "${PKG_DIR}.tgz" ${PKG_DIR}
