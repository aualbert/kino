#import "../kino/lib.typ": *
#set page(width: 100pt, height: 100pt)

#show: animation.with(fps: 10)

#init(x: 15%)
#animate(x: 100%)
#stop()
#animate(hold: 1, x: 10%)

#context {
  polygon(fill: blue.darken(a("d")), (0cm, 0cm), (a("x"), 0cm), (a("x"), 3cm), (
    0cm,
    a("y"),
  ))
}

#finish()

