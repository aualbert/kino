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

  This document contains the documentation for the Typst package `kino`.
  It also provides instructions on how to use the companion Python script `kino.py`.

  = Structure of an animation<structure>

  This section describes the basic structure of an animation.
  It focuses on the `animation` show rule and the functions `a`, `cut` and `finish`.

  An animation is a typst file with the following structure:
  ```typst
  #show: animation
  // animation primitives & content
  #finish()
  ```
  Variables can be animated using animation primitives (e.g., `animate`), initialized using `init`, and their value accessed using `a`.
  The type of an animation variable cannot change during an animation.
  Supported types are `int`, `float`, `ratio`, `angle`, `array` of `function`.
  The size of an array and the types of its elements must be fixed.
  The functions must be defined at $0$, and the type of its image cannot change, e.g.
  ```typst
  #init(a: 0)
  #init(r: (45%, .0))
  #init(f: x => (y => x*y))
  ```
  Animation variables can then be evaluated using `a`, passing the variable name as argument.
  Context must also be provided, e.g.
  ```typst
  #context {
     a("a") + a("f")(.4)(.3)
  }
  ```
  To animate a variable from its current value to a new one, use an animation primitive (see @primitives).
  For example, the following primitives generate $1$ second of frames at a given framerate.
  In this animation, `a("a")` successively evaluates to $0$, $1$ and $2$.
  Meanwhile, `a(r)` interpolates continuously from `(45%, .0)` to `(60%, 1)`.
  Note that given the initial value of `r`, the argument `(60%, 1)` is interpreted as `(60%, 1.0)`.
  ```typst
  #animate( a: 2)
  #meanwhile( r: (60%, 1))
  ```
  If you animate a non-initialized variable, the system infers an initial value of the correct type, e.g.
  ```typst
  // the initial value
  // of g is _ => (0.,)
  #animate(g: t => (t,))
  ```
  If a variable `x` is neither initialized nor animated, `a("x")` evaluates to 0%.
  Finally, the function `cut` splits the output into several segments.
  The exact semantics depends on the output format (see @export).

  #let docs = tidy.parse-module(read("../src/animation.typ"), scope: (
    _show_timeline: _show-timeline,
  ))

  #show-module(docs)

  = Animation primitives<primitives>

  This section describes the different animation primitives.
  They roughly share the same parameters, so we describe only the `animate` primitive in detail.

  Behind the scenes, the system converts each call to an animation primitive into a timeline.
  This timeline describes the value of animation variables at each time step of the animation.
  You can visualize the current timeline using `show-timeline()`:

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

  As seen above, a timeline is divided into blocks.
  Blocks become very useful when coordinating several animation variables.
  Any call to `animate` creates a new block, but you can also specify a block as a parameter.
  By default, the system inserts a cut between each block (see @export).

  Finally, when calling an animation primitive, you can specify how variables are interpolated using the `animation` parameter (see @transitions for details).
  You can also specify the duration of the animation in seconds.

  #let docs = tidy.parse-module(read("../src/primitives.typ"), scope: (
    _show_timeline: _show-timeline,
  ))
  #show-module(docs)

  = Transitions<transitions>

  This section describes the built-in transitions used by the animation primitives.
  A transition is a mathematical function $[0,1] -> [0,1]$.
  Wherever a built-in transition name is expected, you can provide a custom transition instead.
  In addition, you can concatenate transitions using `concat`.

  #let docs = tidy.parse-module(read("../src/transitions.typ"))
  #show-module(docs)

  = Export tool<export>

  You can use this package alongside the Python script kino.py, found at https://github.com/aualbert/kino.
  The requirements are:
  - `python3`
  - `pypdf`
  - `ffmpeg`
  - `typst`
  A nix flake is also provided for convenience.
  The script exports animations to static slides, videos, or revealjs presentations.
  Refer to @cmdsyntax for the syntax of the program kino.py.
  This section describes the different arguments.

  - `INPUT` Input file, either a single scene (a typst file) or a list of scenes to be played in order (a toml file with the following syntax):
  ```toml
  scenes = ["scene1.typ", ...]
  ```
  #colbreak()
  - `h` Displays help.
  - `ROOT` Root of the project, passed to `typst`.
  - `TIMEOUT` Timeout for each operation (`typst` or `ffmpeg`)

  The `OUTPUT` can be one of `video`, `revealjs`, or `slides`.
  Using the `slides` option produces a PDF without animations.
  Using `video` supports any common video format.
  Using `revealjs` outputs a reveal.js presentation as a single HTML file with embedded videos.
  A valid reveal.js installation is still required.
  The following sections describe option-specific arguments.

  == Video and reveal.js export

  The following options are exclusive to video and reveal.js export.

  - `CUT` When to cut.
  Cut animations produce multiple videos or steps in revealjs presentations.
  Manual `cut()` calls are never overridden.
  Can be `none` (no additional cuts besides `cut()`), `scene` (between each scene when using a `.toml` as input), or `all` (between each scene and each block).
  - `FPS` Frame per seconds.
  Does not override the parameters of the `animation` show rule.
  - `PPI` Pixel per inches.

  == Video export

  - `FORMAT` Format of the output video.

  == Reveal.js export

  - `TITLE` Title displayed in browser.
  - `--progress` Enables a progress bar.
  - `TEMPLATE` A custom reveal.js template.
  See for example the default template at `bin/revealjs.html`.
]
\

#figure(caption: "Command-line syntax of kino.py")[
  #set align(left)
  #set text(
    font: "DejaVu Sans Mono",
    size: 9.3pt,
    tracking: -.1pt,
    weight: 500,
  )
  kino.py [-h] #h(2.59cm) INPUT {#text(blue)[video]|#text(green)[revealjs]|#text(red)[slides]} [--cut {none|scene|all}]
  \ #h(1.55cm) [--root ROOT] #h(6.865cm) [--fps FPS]
  \ #h(1.55cm) [--timeout TIMEOUT] #h(5.7cm) [--ppi PPI]
  \ #h(10.94cm) [--format FORMAT]
  \ #h(10.94cm) [--title TITLE]
  \ #h(10.94cm) [--progress]
  \ #h(10.94cm) [--template TEMPLATE]
  \
]<cmdsyntax>
