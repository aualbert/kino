#let project(
  title: "",
  subtitle: "",
  authors: (),
  license: none,
  url: none,
  date: none,
  version: none,
  body,
) = {
  // Set the document's basic properties.
  set document(author: authors, title: title)
  set page(numbering: "1", number-align: center)

  show link: it => {
    set text(
      rgb("#4b69c6"),
      font: "DejaVu Sans Mono",
      size: 9.3pt,
      tracking: -.1pt,
      weight: 500,
    )
    it
  }
  v(4em)

  // Title row.
  align(center)[
    #block(text(weight: 700, 2em, title))
    #version #h(1cm) #date #h(1cm) #license
    #block(link(url))
    #v(1.5em, weak: true)
  ]

  // Author information.
  pad(x: 2em, grid(
    columns: (1fr,) * calc.min(3, authors.len()),
    gutter: 1em,
    ..authors.map(author => align(center, strong(author))),
  ))

  v(4em)

  show heading.where(level: 1): set heading(numbering: "1.")
  show heading.where(level: 3): it => {
    [
      #v(-3em)
      #set text(
        rgb("#4b69c6"),
        font: "DejaVu Sans Mono",
        size: 10pt,
        tracking: -.1pt,
        weight: 500,
      )
      - #it
    ]
  }
  set par(justify: true)

  body
}

#let split-module-by-name(dict, names) = {
  let functions = dict.at("functions")
  let matching = ()
  let others = ()

  for d in functions {
    if d.at("name", default: "") in names {
      matching.push(d)
    } else {
      others.push(d)
    }
  }
  let dict1 = dict
  dict1.insert("functions", matching)
  let dict2 = dict
  dict2.insert("functions", others)

  (dict1, dict2)
}
