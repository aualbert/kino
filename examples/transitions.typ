#import "../lib.typ": *
#set page(width: 10cm, height: 1cm)

#show: animation

#animate(x: 9cm)
#then(x: 0cm, transition: "quad")
#then(x: 9cm, transition: cubic)
#then(x: 0cm, transition: "quart")
#then(x: 9cm, transition: "circ")
#then(x: 0cm, transition: "sin")
#then(x: 9cm, transition: concat(quad, circ))

#context place(dx: a("x"))[#circle(fill: blue)]

#finish()
