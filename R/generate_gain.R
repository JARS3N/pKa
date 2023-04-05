generate_gain<-function(u){
  tibble(
    Gain = diff(u$val[1:150])/diff(u$pH)/1000,
    pH=u$pH[-1]
  )
}
