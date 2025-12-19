#import "@preview/tidy:0.4.3"
#import "@preview/codly:1.3.0": *
#import "template.typ": *
#import "../lib.typ": _show-timeline
#show: codly-init.with()

#let colors = tidy.styles.default.colors
#{
  colors.insert("second", rgb("#e7d9ff"))
  colors.insert("transition", rgb("#f9dfff"))
}

#let show-module(docs) = {
  v(3em)
  tidy.show-module(docs, show-outline: false, colors: colors)
}

#show: project.with(
  title: "Kino",
  subtitle: "Create animations.",
  authors: ("aualbert",),
  version: "0.1.0",
  date: "2025-9-12",
  license: "MIT",
  url: "https://github.com/aualbert/kino",
)

#columns(2, gutter: 5%)[

  This document contains the documentation for the Typst package `kino`, as well as instructions on how to use the compagnion Python script `kino.py`.

  = Structure of an animation<structure>

  This section describe the basic structure of an animation, in particular the `animation` show rule and the functions `init`, `a`, `cut` and `finish`.

  An animation is a typst file with the following structure:
  ```typst
  #show: animation
  // animation primitives & content
  #finish()
  ```
  Variables can be animated using animation primitives, initialized using `init` and their value accessed using `a`. The type of an animation variable cannot change during an animations. Supported types are `int`, `float`, `ratio`, `angle`, `array` of `function`.
  The size of an array and the types of its elements must be fixed. The functions must be defined at $0$, and the type of its image cannot change, e.g.
  ```typst
  #init(a: 0)
  #init(r: (45%, .0))
  #init(f: x => (y => x*y))
  ```
  Animations variables can then be evaluated using `a`, passing as argument the variable name. In addition, context must be provided, e.g.
  ```typst
  #context {
     a("a") + a("f")(.4)(.3)
  }
  ```
  To animate a variable from its current value to a new one, an animation primitive can be used, see @primitives. For example, the following primitives generates $1$ seconds of frames at a given framerate, in which `a("a")` will successively evaluates to $0$, $1$ and $2$, and `a(r)` will interpolate continuously from `(45%, .0)` to `(60%, 1)`. Note that given the initial value of `r`, the argument `(60%, 1)` is interpreted as `(60%, 1.0)`.
  ```typst
  #animate( a: 2)
  #meanwhile( r: (60%, 1))
  ```
  If a non-initialized variable is animated, an initial value of the correct type is infered, e.g.
  ```typst
  // the initial value
  // of g is _ => (0.,)
  #animate(g: t => (t,))
  ```
  If a variable `x` is neither initialized nor animated, `a("x")` evaluates to 0%. Finally, the function `cut`, intuitively, splits the output in several segments. The exact semantics depends on the output format, see @export.

  #let docs = tidy.parse-module(read("../lib.typ"), scope: (
    _show_timeline: _show-timeline,
  ))
  #let (docs1, docs2) = split-module-by-name(docs, (
    "init",
    "a",
    "cut",
    "finish",
    "animation",
  ))

  #show-module(docs1)

  = Animation primitives<primitives>

  This section describes the different animation primitives. They roughly share the same parameters, therefore we only describe the `animate` primitive in details.

  Behind the scenes, the different calls to animation primitive are converted to a timeline describing the value of animation variables at each time step of the animation. The current timeline can be visualized using `show-timeline()`:

  #let var = (
    "x": (
      "0": ((0, 0, 0, 0, 0),),
      "1": ((0, 0, 1, 0, 0),),
      "2": ((0, 1, 1.3, .3, 0),),
    ),
    "y": (
      "0": ((0, 0, 0, 0, 0),),
      "1": ((0, .5, 2, 0, 0),),
    ),
  )

  #[
    #set align(center)
    #_show-timeline(var)
  ]

  As seen above, a timeline is divided into blocks. Blocks become very useful when coordinating several animation variables. Any call to `animate` creates a new block, but a specific block can also be given as parameter. By default, a cut is inserted between each blocks, see @export.

  Finally, when calling an animation primitive, one can specify how variables are interpolated using the `animation` parameter, see @transitions for more details, and the duration of the animation, in seconds.

  #show-module(docs2)

  = Transitions<transitions>

  This section describes the built-in transitions used by the animation primitives. A transition is a mathematical function $[0,1] -> [0,1]$.
  Wherever a built-in transition name is expected, a custom transition can be given instead.

  #let docs = tidy.parse-module(read("../src/transitions.typ"))
  #show-module(docs)

]

= Exportation tool<export>

TODO
