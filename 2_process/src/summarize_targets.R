summarize_targets <- function(ind_file, target_names) {
  ind_tbl <- tar_meta(all_of(target_names)) %>%
    select(tar_name = name, filepath = path, hash = data) %>%
    mutate(filepath = unlist(filepath))

  readr::write_csv(ind_tbl, ind_file)
  return(ind_file)
}
