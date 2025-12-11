/// Linear transition
#let linear(t) = { t }
#let quad(t) = { calc.pow(t, 2) }
#let sin(t) = { t } // TODO

// TODO add other transitions type
#let get_transition(tr) = {
  if tr == "linear" {
    return linear
  } else if tr == "sin" {
    return sin
  } else if tr == "quad" {
    return quad
  } else {
    return tr
  }
}

