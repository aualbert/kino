#import "../../kino/lib.typ": *
#import "theme.typ": *
#set page(width: 128mm, height: 96mm)

#show: animation

#show: theme

#init(x: 80%)
#animate(x: 0%)

#context {
  circle(radius: 50pt * a("x"))
}

#finish()


