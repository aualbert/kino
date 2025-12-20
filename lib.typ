#import "src/transitions.typ": *

#let _begin = state("begin", false)

#let _cut_blocks = state("cut_blocks", ())
#let _loop_blocks = state("loop_blocks", ())

#let _time_block = state("time_block", 1)
#let _time = state("time", 0)

#let _block = state("block", 1)
#let _current_block = state("current block", 1)

#let _get_zero(ty) = {
  if type(ty) == int {
    0
  } else if type(ty) == float {
    0.0
  } else if type(ty) in (angle, length, ratio) {
    ty * 0%
  } else if type(ty) == array {
    ty.map(_get_zero)
  } else if type(ty) == function {
    let zero = _get_zero(ty(.0))
    _ => zero
  }
}

#let _get_default_dict(type: 0%) = {
  ("0": ((_get_zero(type), 0, 0, 0, "linear"),))
}

#let _variables = state("variables", (
  "builtin_pause_counter": _get_default_dict(),
))

/// Terminates the animation. Mandatory.
#let finish() = context {
  if not _begin.get() {
    _begin.update(_ => true)
  }
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
      .map(k => {
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
                total += ho - total + du + dw
              }
              res.join()
            })
        )
      })
      .join(),
  )
}

#let show-timeline() = context {
  if not _begin.get() {
    _show-timeline(_variables.get())
  }
}

#let _scale_value(start, end, t) = {
  start + t * (end - start)
}

#let _get_scaler(ty) = {
  if type(ty) in (float, ratio, length, angle) {
    return _scale_value
  } else if type(ty) == int {
    return (start, end, t) => calc.floor(_scale_value(start, end, t))
  } else if type(ty) == array {
    let scalers = ty.map(_get_scaler)
    return (start, end, t) => scalers
      .zip(start, end)
      .map(i => {
        let (scaler, s, e) = i
        scaler(s, e, t)
      })
  } else if type(ty) == function {
    let scaler = _get_scaler(ty(0))
    return (start, end, t) => (x => scaler(start(x), end(x), t))
  }
}

#let _add_anim(
  block: 1,
  hold: 0,
  duration: 1,
  dwell: 0,
  transition: "linear",
  mode: "append",
  ..args,
) = {
  context {
    let dict = _variables.get()
    for (name, value) in args.named() {
      let name_dict = dict.at(name, default: _get_default_dict(type: value))
      let block_list = name_dict.at(str(block), default: ())

      // Check that values type matches
      if name in dict {
        let new_type = type(value)
        let old_type = type(dict.at(name).at("0").at(0).at(0))
        if new_type == int and old_type == float { value = float(value) } else {
          assert(
            old_type == new_type,
            message: "Cannot modify the type of an animated variable from "
              + str(old_type)
              + " to "
              + str(new_type)
              + ".",
          )
        }
      }
      // check for collision if inserted in place
      if mode == "place" {
        assert(
          block_list.len() == 0,
          message: "collision in the block "
            + str(block)
            + " for variable "
            + name,
        )
      }
    }
  }
  _variables.update(dict => {
    // Compute hold shift depending on the insertion mode
    let shift = 0
    if mode == "append" {
      shift = _get_block_duration_var(dict, block)
    }
    for (name, value) in args.named() {
      let name_dict = dict.at(name, default: _get_default_dict(type: value))
      let block_list = name_dict.at(str(block), default: ())
      block_list.push((value, hold + shift, duration, dwell, transition))
      name_dict.insert(str(block), block_list)
      dict.insert(name, name_dict)
    }
    return dict
  })
}

#let _build_mapping(block, name) = {
  let name_dict = _variables.get().at(name, default: _get_default_dict())
  let end = block
  let start = block - 1
  while not str(start) in name_dict.keys() {
    start -= 1
  }
  let (start_value, _, _, _, _) = name_dict.at(str(start)).at(-1)
  let scaler = _get_scaler(start_value)

  if str(end) in name_dict.keys() {
    let mapping(time) = {
      let start_value_bis = start_value
      for (end_value, hold, duration, dwell, trans) in name_dict.at(str(end)) {
        if hold <= time {
          if time < hold + duration + dwell {
            trans = get_transition(trans)
            time = calc.min(1, calc.max(0, time - hold) / duration)
            return scaler(start_value_bis, end_value, trans(time))
          } else { start_value_bis = end_value }
        } else { break }
      }
      return start_value
    }
    return mapping
  } else {
    return _ => start_value
  }
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

/// Evaluates an animation variable in context.
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
        "kino": (
          "fps": fps,
          "duration": duration,
          "frames": local_frames + 1,
          "from": total_frames,
          "segment": segment,
          "loop": b in loop_blocks,
        ),
      ))
      total_frames += frames
      local_frames = 0
      segment += 1
    }
  }
  page(body)
}

/// The main show rule. Must be applied before any animation primitive is used. The body must contain a call to @finish.
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
            "kino": (
              "fps": fps,
              "duration": duration,
              "frames": local_frames + 1,
              "from": total_frames,
              "segment": segment,
              "loop": b in loop_blocks,
            ),
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


/// Init one or several animation variables.
#let init(..args) = context {
  if not _begin.get() {
    _add_anim(block: 0, ..args)
  }
}

/// Animate variables in a new block, or in the specified block. Change the current block.
/// ```typst
/// #animate(x:50%, y:3cm)
/// #animate(x:20%)
/// #animate(block:2, y:4cm)
/// ```
/// #let var = (
///   "x": (
///     "0": ((0, 0, 0, 0, 0),),
///     "1": ((0, 0, 1, 0, 0),),
///     "2": ((0, 0, 1, 0, 0),),
///   ),
///   "y": (
///     "0": ((0, 0, 0, 0, 0),),
///     "1": ((0, 0, 1, 0, 0),),
///     "2": ((0, 1, 1, 0, 0),),
///   ),
/// )
/// #_show_timeline(var)
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
  ..args,
) = context {
  if not _begin.get() {
    let my_block = if block < 0 { _block.get() } else { block }
    _current_block.update(_ => my_block)
    _add_anim(
      block: my_block,
      hold: hold,
      duration: duration,
      dwell: dwell,
      transition: transition,
      ..args,
    )
    _block.update(b => { if block < 0 { b + 1 } else { b } })
  }
}


/// Animate variables at the start of the current block, _if there is no collision_.
/// ```typst
/// #animate(x:1)
/// #then(x:2)
/// #meanwhile(y:1)
/// #meanwhile(z:3%)
/// //#meanwhile(y:2) raise error
/// ```
/// #let var = (
///   "x": (
///     "0": ((0, 0, 0, 0, 0),),
///     "1": ((0, 0, 1, 0, 0),(0,1,1,0,0)),
///   ),
///   "y": (
///     "0": ((0, 0, 0, 0, 0),),
///     "1": ((0, 0, 1, 0, 0),),
///   ),
///   "z": (
///     "0": ((0, 0, 0, 0, 0),),
///     "1": ((0, 0, 1, 0, 0),),
///   ),
/// )
/// #_show_timeline(var)
#let meanwhile(
  /// -> second
  hold: 0,
  /// -> second
  duration: 1,
  /// -> second
  dwell: 0,
  /// -> transition | str
  transition: "linear",
  ..args,
) = context {
  if not _begin.get() {
    let my_block = _current_block.get()
    _add_anim(
      block: my_block,
      hold: hold,
      duration: duration,
      dwell: dwell,
      transition: transition,
      mode: "place",
      ..args,
    )
  }
}

/// Animate variables in the current block.
/// ```typst
/// #animate(x:1)
/// #then(x:2)
/// #then(y:1)
/// ```
/// #let var = (
///   "x": (
///     "0": ((0, 0, 0, 0, 0),),
///     "1": ((0, 0, 1, 0, 0),(0,1,1,0,0)),
///   ),
///   "y": (
///     "0": ((0, 0, 0, 0, 0),),
///     "1": ((0, 2, 1, 0, 0),),
///   ),
/// )
/// #_show_timeline(var)
#let then(
  /// -> second
  hold: 0,
  /// -> second
  duration: 1,
  /// -> second
  dwell: 0,
  /// -> transition | str
  transition: "linear",
  ..args,
) = context {
  if not _begin.get() {
    let my_block = _current_block.get()
    _add_anim(
      block: my_block,
      hold: hold,
      duration: duration,
      dwell: dwell,
      transition: transition,
      ..args,
    )
  }
}

/// Add waiting time in current or specified block.
#let wait(
  /// -> int
  block: -1,
  /// -> second
  duration: 1,
) = context {
  if not _begin.get() {
    let my_block = if block < 0 { _current_block.get() } else { block }
    _add_anim(
      block: my_block,
      duration: duration,
      builtin_pause_counter: 0%,
    )
  }
}

/// Add a cut at the end of the current block.
#let cut(
  /// Whether the pre-cut segment should loop (revealjs only)
  /// -> bool
  loop: false,
) = context {
  if not _begin.get() {
    let block = _current_block.get()
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
