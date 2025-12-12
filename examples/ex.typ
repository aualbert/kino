#import "../kino/lib.typ": *
#set page(width: 100pt, height: 100pt)

#show: animation

#init(x: 5pt)

#animate(hold: 1, dwell: 1, x: 50pt)
#then(x: 100pt)


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
