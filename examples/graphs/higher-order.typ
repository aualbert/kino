#import "@preview/lilaq:0.5.0" as lq
#import "../../lib.typ": *
#set page(width: auto, height: auto)

#show: animation

#let f0 = x => (y => x * y)
#let f1 = x => (y => f0(x)(y) * x / (1 + calc.pow(y, 2)))
#init(f: f0)
#animate(duration: 5, f: f1)

#context {
  lq.diagram(
    width: 4cm,
    height: 4cm,
    lq.contour(
      min: -20,
      max: 20,
      lq.linspace(-5, 5, num: 20),
      lq.linspace(-5, 5, num: 20),
      (x, y) => a("f")(x)(y),
      map: color.map.icefire,
      fill: true,
    ),
  )
}

#finish()
