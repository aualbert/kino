#import "../lib.typ": *
#set page(width: 15cm, height: auto)

#show: animation

#animate(x: (1, 1))
#then(x: (2, 2))


// #animate(block: 4, x: 1)
// #animate(block: 2, x: 2)
// #then(z: 3)
// #meanwhile(y: 2)

#show-timeline()
#context { _variables.get() }

#finish()
