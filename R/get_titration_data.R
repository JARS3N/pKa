get_titration_data <- function(objs, files) {
  purrr::map_df(setNames(objs, basename(files)),
                function(u) {
                  u$summary %>%
                    mutate(Lot = paste0(u$type, u$lot),
                           sn = u$sn)
                }, .id = 'file') %>%
    group_by(pH, dye) %>%
    mutate(modZ = abs(counts - median(counts)) / mad(counts,
                                                     constant = 1 / qt(.75, df = length(counts) -
                                                                         1))) %>%
    ungroup()
}
