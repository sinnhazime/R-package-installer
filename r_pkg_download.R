required_pkg_name <- commandArgs(TRUE)

if (!requireNamespace("rvest", quietly = TRUE)) install.packages("rvest")
if (!requireNamespace("tidyverse", quietly = TRUE)) install.packages("tidyverse")
if (!requireNamespace("igraph", quietly = TRUE)) install.packages("igraph")
suppressPackageStartupMessages({
  library(rvest)
  library(tidyverse)
  library(igraph)
})

all_package_list_out <- "pkg_list.all.txt"
# package_list_out <- "pkg_list.none.txt"
package_name_out <- "pkg_name.all.txt"
stringi_tgz <- dir_ls() %>% str_subset("^stringi_.+\\.tar\\.gz$")
if (length(stringi_tgz) == 0) stringi_tgz <- ""

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

required_pkg_sort <- 
  all_required_pkg_sort[all_required_pkg_sort %in% c("stringi", required_pkg_name)]
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
required_tgz_sort <- all_pkg_tgz[all_pkg_name %>% factor(levels = required_pkg_sort) %>% order(na.last = NA)]

all_required_tgz_sort %>%
  str_subset("^stringi_.+\\.tar\\.gz$", negate = TRUE) %>% 
  walk(~ {
    download.file(paste0(source_url, ..1), destfile = ..1) ## download files
    Sys.sleep(1)
  })


all_package_list_vec <- 
  all_required_tgz_sort %>% 
  str_replace("^stringi_.+\\.tar\\.gz$", stringi_tgz)

write_lines(all_package_list_vec, all_package_list_out)
write_lines(all_required_pkg_sort, package_name_out)

