#import "../lib.typ": *
#set page(width: 15cm, height: auto)

#show: animation

#animate(duration: 2, x: 1)
#then(y: 2)
#wait()
#then(y: 2)
#animate(block: 1, x: 1)
#animate(x: 2)
#meanwhile(y: 3)
#then(y: 2)
#then(y: 2)
#cut()
#cut()
#animate(duration: 2, block: 1, x: 1)
#then(z: 3)

// #animate(block: 4, x: 1)
// #animate(block: 2, x: 2)
// #then(z: 3)
// #meanwhile(y: 2)

#show-timeline()
#context { _variables.get() }

#finish()
