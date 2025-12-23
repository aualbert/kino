#import "../lib.typ": *
#set page(width: 5cm, height: 5cm)


#let planet(sym, distance, period, color) = {
  ratio => {
    let angle = 360deg * ratio * 1000 / period
    place(
      center + horizon,
      dx: 2.5 * page.width * distance * calc.cos(angle),
      dy: 2.5 * page.width * distance * calc.sin(angle),
      text(fill: color)[#sym],
    )
  }
}

#let mercury = planet("☿", 3%, 88, gray.darken(20%))
#let venus = planet("♀", 5%, 225, orange.darken(20%))
#let earth = planet("♁", 7%, 365, blue.darken(20%))
#let mars = planet("♂", 10%, 687, red.darken(20%))
#let jupiter = planet("♃", 17%, 4333, orange.darken(20%))
#let saturn = planet("♄", 32%, 10759, yellow.darken(20%))
#let uranus = planet("♅", 64%, 30687, aqua.darken(20%))
#let neptune = planet("♆", 95%, 60190, blue.darken(20%))

#show: animation

#animate(duration: 5, t: 30%)

#context {
  place(center + horizon, $dot.o$)
  mercury(a("t"))
  venus(a("t"))
  earth(a("t"))
  mars(a("t"))
  jupiter(a("t"))
  // saturn(a("t"))
  // uranus(a("t"))
  // neptune(a("t"))
}

#finish()


