// TODO then, do not override, have a list instead.

#import "src/transitions.typ": *

#let _begin = state("begin", false)

#let _cut_blocks = state("cut_blocks", ())
#let _loop_blocks = state("loop_blocks", ())

#let _time_block = state("time_block", 1)
#let _time = state("time", 0)

#let _block = state("block", 1)

#let _get_default_dict(type: 0%) = {
  ("0": ((type * 0%, 0, 1, 0, "linear"),))
}

#let _variables = state("variables", (
  "builtin_pause_counter": _get_default_dict(),
))

/// Terminates the animation. Used in conjonction with the @animation show rule.
#let finish() = context {
  if not _begin.get() {
    _begin.update(_ => true)
  }
}

#let _add_anim(block, hold, duration, dwell, transition, name, value) = {
  context {
    if name in _variables.get() {
      assert(
        type(value) == type(_variables.get().at(name).at("0").at(0).at(0)),
        message: "Cannot modify the type of an animated variable.",
      )
    }
  }
  _variables.update(dict => {
    let name_dict = dict.at(name, default: _get_default_dict(type: value))
    let block_list = name_dict.at(str(block), default: ())
    block_list.push((value, hold, duration, dwell, transition))
    name_dict.insert(str(block), block_list)
    dict.insert(name, name_dict)
    return dict
  })
}

#let _has_anim(block, name) = {
  if name in _variables.get() {
    let name_dict = _variables.get().at(name)
    if str(block) in name_dict {
      let block_list = name_dict.at(str(block))
      return block_list.len() != 0
    }
  }
  return false
}

#let _get_max_block_var(var) = {
  calc.max(..var.values().join().keys().map(int))
}

#let _get_max_block() = {
  _get_max_block_var(_variables.get())
}

#let _get_block_duration_var(var, block) = {
  calc.max(
    ..var
      .values()
      .map(dict => dict.pairs())
      .join()
      .map(pair => {
        let (b, l) = pair
        if b != str(block) { 0 } else {
          let (_, ho, du, dw, _) = l.at(-1)
          ho + du + dw
        }
      }),
  )
}

#let _get_block_duration(block) = {
  _get_block_duration_var(_variables.get(), block)
}

#let _get_duration() = {
  let duration = 0
  for block in range(1, _get_max_block() + 1) {
    duration += _get_block_duration(block)
  }
  duration
}

#let _bar(width, color: none) = box(
  [\ ],
  width: width * 25pt,
  radius: 2pt,
  fill: color,
)

#let _show-timeline(timeline) = {
  if not _begin.get() {
    let mblock = _get_max_block_var(timeline)
    grid(
      columns: mblock + 1,
      align: left + bottom,
      inset: 3pt,
      [],
      grid.vline(stroke: (dash: "dashed")),
      ..range(1, mblock + 1)
        .map(b => { ([#b], grid.vline(stroke: (dash: "dashed"))) })
        .flatten(),
      grid.hline(),
      ..timeline
        .keys()
        .filter(k => k != "builtin_pause_counter")
        .map(
          k => {
            let name_dict = timeline.at(k)
            (
              (k,)
                + range(1, mblock + 1).map(b => {
                  let total = 0
                  let res = ()
                  for e in name_dict.at(str(b), default: ()) {
                    let (v, ho, du, dw, t) = e
                    res += (
                      [#_bar(ho - total)#_bar(du, color: blue)#_bar(dw)],
                    )
                    total += ho + du + dw
                  }
                  res.join()
                })
            )
          },
        )
        .join(),
    )
  }
}

#let show-timeline() = context {
  _show-timeline(_variables.get())
}

#let _scale_value(start, end, t) = {
  start + t * (end - start)
}

#let _build_mapping(block, name) = {
  let mapping(time) = {
    let name_dict = _variables.get().at(name, default: _get_default_dict())
    let end = block
    let start = block - 1
    while not str(start) in name_dict.keys() {
      start -= 1
    }
    let (start_value, _, _, _, _) = name_dict.at(str(start)).at(-1)
    let start_value_bis = start_value
    if str(end) in name_dict.keys() {
      for (end_value, hold, duration, dwell, trans) in name_dict.at(str(end)) {
        if hold <= time and time < hold + duration + dwell {
          trans = get_transition(trans)
          time = calc.min(1, calc.max(0, time - hold) / duration)
          return _scale_value(start_value, end_value, trans(time))
        } else { start_value = end_value }
      }
      return start_value_bis // happen for first part
    } else {
      return start_value
    }
  }
  return mapping
}

// unused
#let _map_back_time(time) = {
  let duration = 0
  let block = 0
  for b in range(1, _get_max_block() + 1) {
    let block_duration = _get_block_duration(b)
    if time < duration + block_duration {
      block = b
      break
    } else { duration += block_duration }
  }
  (block, time - duration)
}

// unused
#let _build_full_mapping(name) = {
  let mapping(time) = {
    let (block, rel_time) = _map_back_time(time)
    _build_mapping(block, name)(rel_time)
  }
  return mapping
}

/// Get the value of an animated variable. Can only be used in context as shown below:
/// ```typst
/// #context { a("x") }
/// ```
#let a(
  /// -> str
  name,
) = {
  _build_mapping(_time_block.get(), name)(_time.get())
}

#let _slideshow(body) = context {
  let variables = _variables.final()
  let max_block = calc.max(..variables.values().join().keys().map(int))
  _time.update(_ => 0)
  for b in range(1, max_block + 2) {
    _time_block.update(_ => b)
    page(body)
  }
}

#let _fake(body, fps) = context {
  let variables = _variables.final()
  let cut_blocks = _cut_blocks.final()
  let loop_blocks = _loop_blocks.final()
  let max_block = calc.max(..variables.values().join().keys().map(int))
  if not max_block in cut_blocks {
    cut_blocks = cut_blocks + (max_block,)
  }

  let total_frames = 0
  let local_frames = 0
  let segment = 0

  for b in range(1, max_block + 1) {
    let duration = _get_block_duration_var(variables, b)

    let frames = int(calc.round(fps * duration))
    local_frames += frames

    if b in cut_blocks {
      metadata((
        "fps": fps,
        "duration": duration,
        "frames": local_frames + 1,
        "from": total_frames,
        "segment": segment,
        "loop": b in loop_blocks,
      ))
      total_frames += frames
      local_frames = 0
      segment += 1
    }
  }
  page(body)
}

/// The main show rule. The body must contain a call to @finish as shown below:
/// ```typst
/// #show: animation
/// // animation primitives
/// #finish()
/// ```
#let animation(
  /// -> content
  body,
  /// -> int
  fps: -1,
) = {
  if fps < 0 { fps = int(sys.inputs.at("fps", default: 5)) }
  if int(sys.inputs.at("query", default: 0)) == 1 {
    _fake(body, fps)
  } else if fps == 0 {
    _slideshow(body)
  } else {
    context {
      let variables = _variables.final()
      let cut_blocks = _cut_blocks.final()
      let loop_blocks = _loop_blocks.final()
      let max_block = calc.max(..variables.values().join().keys().map(int))
      if not max_block in cut_blocks {
        cut_blocks = cut_blocks + (max_block,)
      }
      let total_frames = 0
      let local_frames = 0
      let segment = 0

      for b in range(1, max_block + 1) {
        let duration = _get_block_duration_var(variables, b)

        let frames = int(calc.round(fps * duration))
        local_frames += frames

        for frame in range(frames) {
          let time = (duration * frame) / frames
          _time.update(_ => time)
          page(body) //+ place(bottom + right, [#segment])
        }

        _time_block.update(int => int + 1)

        if b in cut_blocks {
          metadata((
            "fps": fps,
            "duration": duration,
            "frames": local_frames + 1,
            "from": total_frames,
            "segment": segment,
            "loop": b in loop_blocks,
          ))
          total_frames += frames
          local_frames = 0
          segment += 1
        }
      }
      _time.update(_ => 0)
      page(body)
    }
  }
}


/// Init animated ratios. Animated ratios start at 0% by default.
#let init(..args) = context {
  if not _begin.get() {
    for (name, value) in args.named() {
      _add_anim(0, 0, 1, 0, "linear", name, value)
    }
  }
}

/// Pause animation
#let pause(block: -1, duration: 1) = context {
  if not _begin.get() {
    let my_block = if block < 0 {
      _block.get()
    } else { block }
    _add_anim(my_block, 0, duration, 0, "linear", "builtin_pause_counter", 0%)
    _block.update(int => { int + 1 })
  }
}

/// TODO
///
/// ```typst
/// #animate(r:50%, x:3cm)
/// ```
#let animate(
  /// A block identifier to start animation at.
  /// -> int
  block: -1,
  /// Waiting time before animation.
  /// -> second
  hold: 0,
  /// Duration of the animation.
  /// -> second
  duration: 1,
  /// Waiting time after animation.
  /// -> second
  dwell: 0,
  /// A transition name or custom transition.
  /// -> transition | str
  transition: "linear",
  /// Variables to animate to the given value.
  /// -> ratio | length
  ..args,
) = context {
  if not _begin.get() {
    let my_block = if block < 0 {
      _block.get()
    } else { block }
    for (name, value) in args.named() {
      _add_anim(my_block, hold, duration, dwell, transition, name, value)
    }
    _block.update(int => { int + 1 })
  }
}

/// TODO
#let meanwhile(
  hold: 0,
  duration: 1,
  dwell: 0,
  transition: "linear",
  ..args,
) = context {
  if not _begin.get() {
    let my_block = calc.max(1, _block.get() - 1)
    for (name, value) in args.named() {
      assert(
        not _has_anim(my_block, name),
        message: "variable " + name + " is already animated in this block",
      )
      _add_anim(my_block, hold, duration, dwell, transition, name, value)
    }
  }
}

/// TODO
#let then(
  hold: 0,
  duration: 1,
  dwell: 0,
  transition: "linear",
  ..args,
) = context {
  if not _begin.get() {
    let my_block = calc.max(1, _block.get() - 1)
    let my_hold = hold + _get_block_duration(my_block)
    for (name, value) in args.named() {
      _add_anim(my_block, my_hold, duration, dwell, transition, name, value)
    }
  }
}

/// Cut the animation into two segments.\
///  The post-cut segment can be cut again.
#let cut(
  /// Whether the pre-cut segment should loop (revealjs only)
  /// -> bool
  loop: false,
) = context {
  if not _begin.get() {
    let block = calc.max(0, _block.get() - 1)
    _cut_blocks.update(array => array + (block,))
    if loop { _loop_blocks.update(array => array + (block,)) }
  }
}

// used for debugging
#let debug() = {
  context {
    page(width: 500pt, height: 500pt)[
      block: #_block.get() \
      begin: #_begin.get() \
      cut blocks: #_cut_blocks.get() \
      duration of last block: #_get_block_duration(calc.max(0, _block.get() - 1)) \
      #_variables.get()
    ]
  }
}

// used for debugging
#let current_value(name) = {
  let name_dict = _variables.get().at(name, default: _get_default_dict())
  let i = _block.get()
  while not str(i) in name_dict.keys() { i -= 1 }
  let (value, _, _, _, _) = name_dict.at(str(i))
  return value
}
