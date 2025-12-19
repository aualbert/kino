#import "@preview/cetz:0.4.0"
#import "@preview/cetz-plot:0.1.2"
#import "../../kino/lib.typ": *
#set page(width: auto, height: auto)

#show: animation

#init(e: 0.1)
#animate(duration: 3, e: 2)

#context {
  cetz.canvas({
    import cetz.draw: *
    import cetz-plot: *
    let f = x => calc.pow(calc.pow(x, 2), a("e"))
    plot.plot(
      axis-style: "school-book",
      x-tick-step: none,
      y-tick-step: none,
      {
        plot.add(fill: true, domain: (-1, 1), f)
      },
    )
  })
}

#finish()
