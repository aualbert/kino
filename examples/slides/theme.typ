#let theme(body) = {
  place(
    bottom + right,
    [#sys.inputs.at("scene", default: 0)/#sys.inputs.at("total_scenes", default: 0)],
  )
  body
}
