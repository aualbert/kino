#import "@preview/lilaq:0.5.0" as lq
#import "../../kino/lib.typ": *
#set page(width: auto, height: auto)

#show: animation

#init(e: 0)
#animate(duration: 3, e: 2 * calc.pi)

#context {
  let xs = lq.linspace(0, 4)
  lq.diagram(
    xlim: (0, 4),
    ylim: (-2, 2),
    lq.fill-between(
      xs,
      xs.map(calc.sin),
      y2: xs.map(t => calc.cos(t + a("e"))),
    ),
  )
}

#finish()
