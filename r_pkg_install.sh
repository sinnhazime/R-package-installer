# change here #
pkg_dir="${HOME}/r_pkg_tgz"
install_dir="${HOME}/R/x86_64-redhat-linux-gnu-library/3.6"
###############

set -eu

package_list="pkg_list.none.txt" # "pkg_list.all.txt" for installing all downloaded packageds

mkdir $install_dir -p
cd $pkg_dir
Rscript --vanilla --slave r_pkg_check_installed.R

while IFS= read -r line; do
  if [ ! "$line" = "" ]; then
    R CMD INSTALL "$line" --library="$install_dir"
  fi
done < "$package_list"
