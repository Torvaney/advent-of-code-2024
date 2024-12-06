import data/grid
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import glitzer/progress

pub type MapTile {
  Blank
  Obstruction
}

pub type GuardLocation {
  GuardLocation(at: grid.Coordinate, facing: grid.Direction)
}

pub type Guard {
  Guard(location: GuardLocation, history: List(GuardLocation))
}

pub type Puzzle {
  Puzzle(map: grid.Grid(MapTile), guard: Guard)
}

type ParsingMapTile {
  ParsingTile(MapTile)
  ParsingGuard(grid.Direction)
}

pub fn parse(input: String) -> Result(Puzzle, String) {
  use puzzle_grid <- result.try(
    grid.from_string(input, with: fn(x) {
      case x {
        "." -> Ok(ParsingTile(Blank))
        "#" -> Ok(ParsingTile(Obstruction))
        "^" -> Ok(ParsingGuard(grid.North))
        ">" -> Ok(ParsingGuard(grid.East))
        "<" -> Ok(ParsingGuard(grid.West))
        "v" -> Ok(ParsingGuard(grid.South))
        x -> Error("Unknown character in grid '" <> x <> "'")
      }
    }),
  )

  use #(guard_coord, guard_facing) <- result.try(
    grid.find_map(puzzle_grid, fn(t) {
      case t {
        ParsingGuard(dir) -> Ok(dir)
        ParsingTile(_) -> Error(Nil)
      }
    })
    |> result.replace_error("No guard found in grid!"),
  )

  let guard_loc = GuardLocation(at: guard_coord, facing: guard_facing)

  Ok(Puzzle(
    map: grid.map(puzzle_grid, fn(_, val) {
      case val {
        ParsingTile(tile) -> tile
        ParsingGuard(_) -> Blank
      }
    }),
    guard: Guard(location: guard_loc, history: [guard_loc]),
  ))
}

// Part 1

type EndState {
  Loop
  OffMap
}

fn check_loop(guard: Guard) -> Result(Guard, EndState) {
  // Ignore the first entry in history because that's always
  // just the current state
  case list.contains(list.drop(guard.history, 1), guard.location) {
    False -> Ok(guard)
    True -> Error(Loop)
  }
}

fn move_guard(guard: Guard, to coord: grid.Coordinate) -> Guard {
  let new_loc = GuardLocation(at: coord, facing: guard.location.facing)

  Guard(location: new_loc, history: [new_loc, ..guard.history])
}

fn turn_guard(guard: Guard) -> Guard {
  let new_loc =
    GuardLocation(
      at: guard.location.at,
      facing: grid.clockwise(guard.location.facing, for: 2),
    )

  Guard(location: new_loc, history: [new_loc, ..guard.history])
}

fn step(map: grid.Grid(MapTile), guard: Guard) -> Result(Guard, EndState) {
  let new_coord = grid.shift(guard.location.at, guard.location.facing)

  case grid.get(map, new_coord) {
    Ok(Blank) -> move_guard(guard, new_coord) |> check_loop()
    Ok(Obstruction) -> turn_guard(guard) |> check_loop()
    Error(Nil) -> Error(OffMap)
  }
}

fn step_until(map: grid.Grid(MapTile), guard: Guard) -> #(Guard, EndState) {
  case step(map, guard) {
    Ok(stepped) -> step_until(map, stepped)
    Error(end) -> #(guard, end)
  }
}

pub fn solve1(input: Puzzle) -> Result(Int, String) {
  step_until(input.map, input.guard)
  |> fn(result) { { result.0 }.history }
  |> list.map(fn(guard) { guard.at })
  |> list.unique()
  |> list.length()
  |> Ok()
}

// Part 2

fn causes_loop(puzzle: Puzzle, new_obstruction: grid.Coordinate) -> Bool {
  let map_with_obstruction = grid.set(puzzle.map, new_obstruction, Obstruction)

  case step_until(map_with_obstruction, puzzle.guard) {
    #(_, Loop) -> True
    #(_, OffMap) -> False
  }
}

pub fn solve2(input: Puzzle) -> Result(Int, String) {
  let coordinates_to_search =
    // Since there's only one obstruction allowed, we know that the placement
    // will occur within the path of the naive run
    step_until(input.map, input.guard)
    |> fn(result) { { result.0 }.history }
    |> list.map(fn(g) { g.at })
    |> list.unique()
    |> list.filter(fn(coord) { coord != input.guard.location.at })

  let n_items = list.length(coordinates_to_search)
  let bar =
    progress.new_bar()
    |> progress.with_length(80)
    |> progress.with_fill(progress.char_from_string("#"))
    |> progress.with_fill_head(progress.char_from_string(">"))
    |> progress.with_empty(progress.char_from_string(" "))
    |> progress.with_left_text("Searching for loops... |")
    |> progress.with_right_text("| 0/" <> int.to_string(n_items))

  let result =
    list.index_map(coordinates_to_search, fn(coord, ix) {
      let ticks = { ix * 100 } / n_items
      progress.print_bar(
        progress.tick_by(bar, ticks)
        |> progress.with_right_text(
          "| " <> int.to_string(ix) <> "/" <> int.to_string(n_items),
        ),
      )

      causes_loop(input, coord)
    })
    |> list.count(fn(x) { x })

  progress.print_bar(progress.finish(bar))

  Ok(result)
}
