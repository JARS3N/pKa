generate_ef_range <- function(tlines) {
  min10 <- function(z) {
    min(z) + ((max(z) - min(z)) / 10)
  }
  max10 <- function(z) {
    max(z) - ((max(z) - min(z)) / 10)
  }
  LowLine <- function(u) {
    b <- min10(u)

    which(abs(u - b) == min(abs(u - b)))
  }
  HighLine <-
    function(u) {
      b <- max10(u)
      which(abs(u - b) == min(abs(u - b)))
    }
  group_by(tlines, dye) %>%
    summarise(`Low pH` = pH[LowLine(val)],
              `High pH` = pH[HighLine(val)]) %>%
    mutate(dye = c("CL" = "Clear", "PR" = "Phenol Red")[dye])
}
