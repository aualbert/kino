#import "../kino/lib.typ": *
#set page(width: 100pt, height: 100pt)

//#show: animation

#init(x: 1pt)

#let f(x) = 2 * x
#animate(hold: 1, dwell: 1, x: 2pt)
#then(x: 5pt, transition: f)
#animate(x: 20pt)
#animate(y: 2cm)
#animate(y: 1cm)
#animate(y: 2cm)

#page(width: 30cm, height: 10cm)[ #show-timeline()]

#context {
  polygon(
    fill: blue.darken(a("d")),
    (0cm, 0cm),
    (a("x"), 0cm),
    (a("x"), 3cm),
    (
      0cm,
      a("y"),
    ),
  )
}

#finish()
