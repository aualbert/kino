#import "../kino/lib.typ": *
#set page(width: 100pt, height: 100pt)

#show: animation

#init(x: 10pt)

#animate(hold: 1, dwell: 1, x: 80pt)
#meanwhile(duration: 3, y: 60pt)
#then(x: 30pt)

//#page(width: 10cm)[#show-timeline()]

#let f(t) = 3 * t

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
