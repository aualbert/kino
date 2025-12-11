#import "@preview/tidy:0.4.3"
#import "@preview/codly:1.3.0": *
#import "template.typ": *
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

  This document contains the documentation for the Typst package `kino`. For instructions on how to use the compagnion Python script `kino.py`, please refer to the readme in the project repository.

  = Structure of an animation

  This section describe the `animation` show rule, the special functions `a`, `cut` and `finish`, and their usage.

  #let docs = tidy.parse-module(read("../lib.typ"))
  #let (docs1, docs2) = split-module-by-name(docs, (
    "a",
    "cut",
    "finish",
    "animation",
  ))

  #show-module(docs1)

  = Animation primitives

  This section describes the animation primitives that can be used in animations. Animations primitives share roughfly the same paramete, thereforen we only describe the `animate` primitive in details.
  TODO custom types in and transition type

  #show-module(docs2)

  = Transitions

  This section describes the built-in transitions used by the animation primitives. A transition is a mathematical function $[0,1] -> [0,1]$.
  Wherever a built-in transition name is expected, a custom transition can be given instead.

  #let docs = tidy.parse-module(read("../src/transitions.typ"))
  #show-module(docs)

]
