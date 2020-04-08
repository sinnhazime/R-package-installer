#! /bin/bash

# change here #
pkg_dir="${HOME}/r_pkg_tgz"
###############

set -eu
cwd=$PWD

mkdir $pkg_dir -p
cd $pkg_dir
# download stringi (NO-INTERNET version)
# see https://github.com/gagolews/stringi/blob/master/INSTALL
wget https://github.com/gagolews/stringi/archive/master.zip -O stringi.zip
unzip stringi.zip
sed -i '/\/icu..\/data/d' stringi-master/.Rbuildignore
R CMD build stringi-master
rm stringi.zip
rm stringi-master -rf

cd $cwd
Rscript --slave --vanilla r_pkg_download.R
