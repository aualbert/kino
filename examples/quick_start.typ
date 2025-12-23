#import "../lib.typ": *
#set page(width: auto, height: auto)

// main show rule
#show: animation

// initialize an animation variable
#init(x: (3cm, 2.))

// animate x, for a duration of 1 second
#animate(x: (0cm, 3))

// then animate x using a sine transition
#then(transition: "sin", x: (1cm, 1))

// meanwhile animate y pointwise from the initial value t => 0, for a duration of 2 seconds.
#meanwhile(duration: 2, y: t => (2cm * t))

// context is mandatory to evaluates animation variables
#context {
  // evaluate x
  let (w, h) = a("x")

  // evaluate y
  rect(width: w, height: a("y")(h))
}

// mandatory
#finish()
