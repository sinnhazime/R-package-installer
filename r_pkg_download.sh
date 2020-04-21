#! /bin/bash

# change here #
pkg_dir="${HOME}/r_pkg_tgz"
###############

set -eu
cwd=$PWD

mkdir -p $pkg_dir
cd $pkg_dir
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

cd $cwd
Rscript --slave --vanilla r_pkg_download.R

cd $PWD
tar cvzf ${pkg_dir} r_pkg_tgz
