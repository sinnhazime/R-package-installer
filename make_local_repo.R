#!/usr/bin/env Rscript

if (!requireNamespace("optparse", quietly = TRUE)) install.packages("optparse")
suppressPackageStartupMessages(library(optparse))

opts_list <- list(
  make_option(c("-q", "--quiet"),
              action = "store_true", 
              default = FALSE,
              help = "Print little output"),
  make_option(c("-o", "--output"),
              type = "character",
              default = "r_repos",
              help = "An output directory where packages will be downloaded. [Default: %default]"),
  make_option(c("-r", "--r_ver"),
              type = "character",
              default = paste(R.version$major, R.version$minor, sep = "."),
              help = "The version of R in the computer you want to install packages. 
                [Default: the version of R where this script is running: %default]"),
  make_option(c("-b", "--bioc_ver"),
              type = "character",
              default = if (requireNamespace("BiocManager", quietly = TRUE)) as.character(BiocManager::version()) else NA_character_,
              help = "The version of BiocManager in the computer you want to install packages. 
                [Default: the version of BiocManager in the computer where this script is running: %default]"),
  make_option(c("-t", "--type"),
              type = "character",
              default = "source",
              help = "One of 'source', 'mac.binary', 'mac.binary.el-capitan', 'win.binary'. 
                If you got error when you specified one of the binary types, please see 'https://cloud.r-project.org/bin/' to check whether packages are available for your R version.
                [Default: %default]")
)

parser <- OptionParser(
  usage = "usage: %prog [options] package1 package2 ...", 
  option_list = opts_list,
  description = "
R package installer: clone R packages you need and thier dependencies for computers with no internet access.
CRAN and Bioconductor packages can be specified. GitHub packages are currently not available.")
OPTS <- parse_args(parser, positional_arguments = c(1, Inf))

if (!requireNamespace("miniCRAN", quietly = TRUE)) install.packages("miniCRAN")
suppressPackageStartupMessages(library(miniCRAN))

# get URLs of R package repositories
if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
repos <- BiocManager::repositories(version = OPTS$options$bioc_ver)

# get a matrix for available packages
avail_pkgs_list <- vector("list", length(repos))
for (i in seq_along(repos)) {
  avail_pkgs_list[[i]] <- pkgAvail(repos[[i]], type = OPTS$options$type, Rversion = OPTS$options$r_ver, quiet = OPTS$options$quiet)
}
avail_pkgs <- do.call(rbind, avail_pkgs_list)
rm("avail_pkgs_list")

# solve package dependencies
req_pkgs <- pkgDep(OPTS$args, availPkgs = avail_pkgs, quiet = OPTS$options$quiet)

# clone dependencies
dir.create(OPTS$options$output)
repo_pkgs <- 
  makeRepo(req_pkgs, 
           path = OPTS$options$output, 
           type = OPTS$options$type, 
           repos = repos, 
           Rversion = OPTS$options$r_ver, 
           quiet = OPTS$options$quiet)

# check
repo_pkgs_names <- sub("_.*", "", basename(repo_pkgs))
failed_pkgs <- setdiff(req_pkgs, repo_pkgs_names)
if (length(failed_pkgs) == 0L) {
  if (!OPTS$options$quiet) message("==============================\nAll packages were successfully downloaded.")
} else {
  warning(sprintf("%i packages were failed to download: %s", length(failed_pkgs), paste0(failed_pkgs, collapse = ", ")))
}

# download stringi (NO-INTERNET version)
# see https://github.com/gagolews/stringi/blob/master/INSTALL
if (OPTS$options$type == "source" && "stringi" %in% repo_pkgs_names) {
  stringi_path <- repo_pkgs[repo_pkgs_names == "stringi"]
  repo_dir <- dirname(stringi_path)
  stringi_nonet_zip <- file.path(repo_dir, "stringi.zip")
  download.file("https://github.com/gagolews/stringi/archive/master.zip", stringi_nonet_zip, quiet = OPTS$options$quiet)
  unzip(stringi_nonet_zip, exdir = repo_dir)
  file.remove(stringi_path)
  cwd <- getwd()
  setwd(repo_dir)
  system2("R", c("CMD", "build", "stringi-master"))
  setwd(cwd)
  file.remove(stringi_nonet_zip)
  file.remove(file.path(repo_dir, "stringi-master", list.files(file.path(repo_dir, "stringi-master"), recursive = TRUE, all.files = TRUE)))
  file.remove(rev(list.dirs(file.path(repo_dir, "stringi-master"), full.names = TRUE, recursive = TRUE)))
  if (!OPTS$options$quiet) message("==============================\n'stringi' was replaced to the NO-INTERNET version.")
}

x <- updateRepoIndex(OPTS$options$output, type = OPTS$options$type, Rversion = OPTS$options$r_ver)

if (!OPTS$options$quiet) message("==============================")
out_dir_path <- file.path(getwd(), OPTS$options$output)
message(
  sprintf(
    "You can install R packages by 'install.packages(c(%s), type = '%s', repos = '%s')' after you copy '%s' to the computer where you want to install R packages.",
    paste0(paste0("'", OPTS$args, "'"), collapse = ", "),
    OPTS$options$type,
    paste0("file://", out_dir_path),
    OPTS$options$output
  )
)
# install.packages("forecast", type = OPTS$options$type, repos = paste0("file://", out_dir_path))
