#import "@preview/lilaq:0.5.0" as lq
#import "../../kino/lib.typ": *
#set page(width: auto, height: auto)

#show: animation

#init(c: (.0, .8, 5.))
#animate(c: (.0, 1.7, 5.))
#then(c: (.0, .8, 5.))

#context {
  let xs = lq.linspace(0, 5)
  lq.diagram(
    width: 5cm,
    height: 5cm,
    xlim: (0, 5),
    ylim: (0, 5),
    xaxis: (
      ticks: ("", "PA", "PB", "VB", "VA").enumerate(),
      subticks: none,
    ),
    yaxis: (
      ticks: ("", "PB", "PA", "VA", "VB").enumerate(),
      subticks: none,
    ),
    lq.rect(1, 2, width: 3, height: 1, fill: blue),
    lq.rect(2, 1, width: 1, height: 3, fill: blue),
    lq.plot(
      smooth: true,
      mark: none,
      (0, 4.2, 5),
      a("c"),
      stroke: blue + 1.2pt,
    ),
  )
}

#finish()
