#let _begin = state("begin", false)

#let _stop_blocks = state("stop_blocks", ())

#let _time_block = state("time_block", 1)
#let _time = state("time", 0)

#let _block = state("block", 1)
#let _default_dict = ("0": (0%, 0, 1, 0, "linear"))
#let _variables = state("variables", ("builtin_pause_counter": _default_dict))

#let finish() = context {
  _begin.update(_ => true)
}

#let _add_anim(block, hold, duration, dwell, transition, name, value) = {
  _variables.update(dict => {
    let name_dict = dict.at(name, default: _default_dict)
    name_dict.insert(str(block), (value, hold, duration, dwell, transition))
    dict.insert(name, name_dict)
    return dict
  })
}

#let _get_max_block() = {
  calc.max(.._variables.get().values().join().keys().map(int))
}

#let _get_block_duration(block) = {
  calc.max(.._variables
    .get()
    .values()
    .map(dict => dict.pairs())
    .join()
    .map(pair => {
      let (b, (_, ho, du, dw, _)) = pair
      if b == str(block) { ho + du + dw } else { 0 }
    }))
}

#let _get_duration() = {
  let duration = 0
  for block in range(1, _get_max_block() + 1) {
    duration += _get_block_duration(block)
  }
  duration
}

// TODO add other transitions type
#let _get_transition(str) = {
  if str == "sin" {
    let trans(x) = { x } // TODO
    return trans
  } else if str == "quad" {
    let trans(x) = { calc.pow(x, 2) }
    return trans
  } else {
    let trans(x) = { x }
    return trans
  }
}

#let _scale_value(start, end, t) = {
  start + t * (end - start)
}

#let _build_mapping(block, name) = {
  let mapping(time) = {
    let name_dict = _variables.get().at(name, default: _default_dict)
    let end = block
    let start = block - 1
    while not str(start) in name_dict.keys() {
      start -= 1
    }
    let (start_value, _, _, _, _) = name_dict.at(str(start))
    if str(end) in name_dict.keys() {
      let (end_value, hold, duration, _, trans) = name_dict.at(str(end))
      trans = _get_transition(trans)
      time = calc.min(1, calc.max(0, time - hold) / duration)
      return _scale_value(start_value, end_value, trans(time))
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

#let a(name) = {
  _build_mapping(_time_block.get(), name)(_time.get())
}

#let animation(body, fps: 30) = context {
  let variables = _variables.final()
  let stop_blocks = _stop_blocks.final()
  let max_block = calc.max(..variables.values().join().keys().map(int))
  let total_frames = 0

  for b in range(1, max_block + 1) {
    let duration = calc.max(..variables
      .values()
      .map(dict => dict.pairs())
      .join()
      .map(pair => {
        let (bb, (_, ho, du, dw, _)) = pair
        if bb == str(b) { ho + du + dw } else { 0 }
      }))
    let frames = int(calc.round(fps * duration))
    total_frames += frames
    //page(width: 300pt, height:300pt)[frames: #frames #debug()]
    for frame in range(frames) {
      let time = (duration * frame) / frames
      //page[#b/#max_block, #(calc.round(time * 1000) / 1000)/#duration]
      _time.update(_ => time)
      page(body)
    }
    metadata(("fps": fps, "duration": duration, "frames": total_frames))
    total_frames = 0
    _time_block.update(int => int + 1)
  }
  _time.update(_ => 0)
  page(body)
}

#let init(..args) = context {
  if not _begin.get() {
    for (name, value) in args.named() {
      _add_anim(0, 0, 1, 0, "linear", name, value)
    }
  }
}

#let pause(block: -1, duration: 1) = context {
  if not _begin.get() {
    let my_block = if block < 0 {
      _block.get()
    } else { block }
    _add_anim(my_block, 0, duration, 0, "linear", "builtin_pause_counter", 0%)
    _block.update(int => { int + 1 })
  }
}

#let animate(
  block: -1,
  hold: 0,
  duration: 1,
  dwell: 0,
  transition: "linear",
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
      _add_anim(my_block, hold, duration, dwell, transition, name, value)
    }
  }
}

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

#let stop() = context {
  if not _begin.get() {
    let block = _block.get()
    _stop_blocks.update(array => array + (block,))
  }
}

// used for debugging
#let debug() = {
  context {
    page(width: 500pt, height: 500pt)[
      block: #_block.get() \
      begin: #_begin.get() \
      stop blocks: #_stop_blocks.get() \
      duration of last block: #_get_block_duration(calc.max(0, _block.get() - 1)) \
      #_variables.get()
    ]
  }
}

// used for debugging
#let current_value(name) = {
  let name_dict = _variables.get().at(name, default: _default_dict)
  let i = _block.get()
  while not str(i) in name_dict.keys() { i -= 1 }
  let (value, _, _, _, _) = name_dict.at(str(i))
  return value
}
