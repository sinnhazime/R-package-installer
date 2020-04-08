# change here#
local_pkg_dir <- "~/r_pkg_tgz"
required_pkg_name <- c("tidyverse", "furrr", "fs", "cowplot", "patchwork", "argparse", "reticulate", "conflicted", "BiocManager", "config", "latex2exp")
###############

# ok_pkg <- 
# c("R6_2.4.1.tar.gz", 
# "prettyunits_1.1.1.tar.gz", 
# "rlang_0.4.5.tar.gz", 
# "rstudioapi_0.11.tar.gz", 
# "magrittr_1.5.tar.gz", 
# "praise_1.0.0.tar.gz", 
# "sys_3.3.tar.gz", 
# "highr_0.8.tar.gz", 
# "yaml_2.2.1.tar.gz", 
# "rematch_1.0.1.tar.gz", 
# "base64enc_0.1-3.tar.gz", 
# "fansi_0.4.1.tar.gz", 
# "BH_1.72.0-3.tar.gz", 
# "plogr_0.2.0.tar.gz", 
# "curl_4.3.tar.gz", 
# "utf8_1.1.4.tar.gz", 
# "whisker_0.4.tar.gz", 
# "listenv_0.8.0.tar.gz", 
# "farver_2.0.3.tar.gz", 
# "labeling_0.3.tar.gz", 
# "RColorBrewer_1.1-2.tar.gz", 
# "viridisLite_0.3.0.tar.gz", 
# "findpython_1.0.5.tar.gz", 
# "ps_1.3.2.tar.gz", 
# "backports_1.1.6.tar.gz", 
# "pkgconfig_2.0.3.tar.gz", 
# "digest_0.6.25.tar.gz", 
# "clipr_0.7.0.tar.gz", 
# "BiocManager_1.30.10.tar.gz", 
# "evaluate_0.14.tar.gz", 
# "generics_0.0.2.tar.gz", 
# "glue_1.4.0.tar.gz", 
# "DBI_1.1.0.tar.gz", 
# "jsonlite_1.6.1.tar.gz", 
# "xml2_1.3.0.tar.gz", 
# "rappdirs_0.3.1.tar.gz", 
# "Rcpp_1.0.4.tar.gz", 
# "fs_1.4.1.tar.gz", 
# "ellipsis_0.3.0.tar.gz", 
# "purrr_0.3.3.tar.gz", 
# "askpass_1.1.tar.gz", 
# "config_0.3.tar.gz", 
# "assertthat_0.2.1.tar.gz", 
# "mime_0.9.tar.gz", 
# "xfun_0.12.tar.gz", 
# "stringi_1.4.7.tar.gz", 
# "colorspace_1.4-1.tar.gz", 
# "withr_2.1.2.tar.gz", 
# "crayon_1.3.4.tar.gz", 
# "gtable_0.3.0.tar.gz", 
# "globals_0.12.5.tar.gz", 
# "processx_3.4.2.tar.gz", 
# "rprojroot_1.3-2.tar.gz", 
# "memoise_1.1.0.tar.gz", 
# "lifecycle_0.2.0.tar.gz", 
# "argparse_2.0.1.tar.gz", 
# "plyr_1.8.6.tar.gz", 
# "htmltools_0.4.0.tar.gz", 
# "lubridate_1.7.8.tar.gz", 
# "reticulate_1.15.tar.gz", 
# "vctrs_0.2.4.tar.gz", 
# "openssl_1.4.1.tar.gz", 
# "markdown_1.1.tar.gz", 
# "tinytex_0.21.tar.gz", 
# "stringr_1.4.0.tar.gz", 
# "munsell_0.5.0.tar.gz", 
# "cli_2.0.2.tar.gz")


###
if (!requireNamespace("fs", quietly = TRUE)) install.packages("fs")
if (!requireNamespace("rvest", quietly = TRUE)) install.packages("rvest")
if (!requireNamespace("tidyverse", quietly = TRUE)) install.packages("tidyverse")
if (!requireNamespace("igraph", quietly = TRUE)) install.packages("igraph")
library(rvest)
library(tidyverse)
library(igraph)
library(fs)

package_list_out <- "pkg_list.txt"
stringi_tgz <- dir_ls() %>% str_subset("^stringi_.+\\.tar\\.gz$")

## web scraping 1: check dependency
lib_url <- "https://cran.r-project.org/web/packages/{pkg}/index.html"

i <- installed.packages()
default_pkg <- i[ i[,"Priority"] %in% c("base","recommended"), "Package"]


read_html_pkg <- function(pkg) {
  pkg_url <- url(str_glue(lib_url), "rb")
  res <- try(read_html(pkg_url))
  close(pkg_url)
  if ("try-error" %in% class(res)) {
    warning(str_glue("NOT EXIST: {pkg}"))
    res <- vector("character")
    assign("non_valid_pkg", c(non_valid_pkg, pkg), envir = globalenv())
  }
  res
}

get_depended_pkg <- function(pkg) {
  pkg_html <- 
    pkg %>% 
    read_html_pkg()
  if ("character" %in% class(pkg_html)) return(vector("character"))
  pkg_html_table <- 
    pkg_html %>% 
    html_node("body") %>% 
    html_node("table")
  if ("xml_missing" %in% class(pkg_html_table)) {
    warning(str_glue("TABLE NOT FOUND: {pkg}"))
    return(vector("character"))
  }
  pkg_info_tbl <- 
    pkg_html_table %>% 
    html_table() %>% 
    as_tibble() %>% 
    `colnames<-`(c("label", "value"))
  depended_pkg <- 
    pkg_info_tbl %>% 
    filter(label %in% c("Depends:", "Imports:", "LinkingTo:")) %>% 
    separate_rows(value, sep = ", ") %>% 
    mutate(value = str_extract(value, "^[:graph:]+")) %>% 
    `[[`("value") %>% 
    setdiff("R")
  depended_pkg %>% `names<-`(rep_along(depended_pkg, pkg))
}

non_valid_pkg <- vector("character")
searched_pkg <- vector("character")

search_pkg <- required_pkg_name %>% setdiff(default_pkg)
dependency_result <- vector("character")
while (length(search_pkg) > 0) {
  pkg_char <- str_c(search_pkg, collapse = ", ")
  message(paste0("Searching: ", pkg_char))
  dependency_result <- # update
    search_pkg %>% 
    map(get_depended_pkg) %>% 
    do.call(`c`, .) %>% 
    c(dependency_result)
  searched_pkg <- c(searched_pkg, search_pkg)
  search_pkg <- 
    dependency_result %>% 
    unique() %>% 
    setdiff(searched_pkg) %>% 
    setdiff(default_pkg)
}

all_required_pkg_sort <- 
  dependency_result %>% 
  enframe() %>% 
  graph_from_data_frame() %>% 
  topo_sort("in") %>% 
  names() %>% 
  setdiff(default_pkg)

## web scraping 2: download files
source_url <- "https://ftp.yz.yamagata-u.ac.jp/pub/cran/src/contrib/"
recall_html <- read_html(source_url)
all_pkg_tgz <- 
  recall_html %>% 
  html_nodes("a") %>%   ## find all links
  html_attr("href") %>% ## pull out url
  str_subset("\\.tar\\.gz") ## pull out tar.tz links
all_pkg_name <- 
  all_pkg_tgz %>% 
  str_remove("_.+\\.tar\\.gz$")

# check
non_cran_pkg <- setdiff(all_required_pkg_sort, all_pkg_name)
if (length(non_cran_pkg) != 0) {stop(str_glue("NOT REGISTERED IN CRAN: {pkg_char}", pkg_char = str_c(non_cran_pkg, collapse = ", ")))}

all_required_tgz_sort <- all_pkg_tgz[all_pkg_name %>% factor(levels = all_required_pkg_sort) %>% order(na.last = NA)]

#
# all_required_tgz_sort <- all_required_tgz_sort %>% setdiff(ok_pkg)
#
all_required_tgz_sort %>%
  str_subset("^stringi_.+\\.tar\\.gz$", negate = TRUE) %>% 
  walk(~ {
    download.file(paste0(source_url, ..1), destfile = fs::path(local_pkg_dir, ..1)) ## download files
    Sys.sleep(1)
  })

setwd(local_pkg_dir)

all_required_tgz_sort %>% 
  str_replace("^stringi_.+\\.tar\\.gz$", stringi_tgz) %>% 
  write_lines(fs::path(local_pkg_dir, package_list_out))
