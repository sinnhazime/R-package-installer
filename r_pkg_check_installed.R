DIR <- commandArgs(TRUE)[1]

i <- installed.packages()
installed_pkg <- i[, "Package"]
all_pkg_tgz <- readLines(paste0(DIR, "/pkg_list.all.txt"))
all_pkg_name <- readLines(paste0(DIR, "/pkg_name.all.txt"))
needed_pkg_tgz <- all_pkg_tgz[!all_pkg_name %in% installed_pkg]
writeLines(needed_pkg_tgz, paste0(DIR, "/pkg_list.none.txt"))