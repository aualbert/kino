#import "../../lib.typ": *
#import "theme.typ": *
#set page(width: 128mm, height: 96mm)

#show: animation

#show: theme

#animate(x: 50%)
#cut()
#animate(x: 100%)

#context {
  polygon((0cm, 0cm), (0cm, 5cm), (a("x"), 5cm), (a("x"), 0cm))
}

#finish()

