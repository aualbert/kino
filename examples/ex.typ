#import "../lib.typ": *
#set page(width: 10cm, height: auto)

#show: animation

#animate(x: 1)
#then(x: 2)
#then(y: 1)
#meanwhile(y: 3)
#animate(x: 2)
#meanwhile(y: 3)
#animate(block: 4, x: 1)
#animate(block: 2, x: 2)
#then(z: 3)
#meanwhile(y: 2)

#context {
  let (_, ho, du, dw, _) = _variables.get().at("x").at("2").at(-1)
}

#show-timeline()

#finish()
