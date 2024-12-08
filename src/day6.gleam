import data/coord
import data/grid
import gleam/int
import gleam/list
import gleam/result
import gleam/set
import glitzer/spinner

pub type MapTile {
  Blank
  Obstruction
}

pub type GuardLocation {
  GuardLocation(at: grid.Coordinate, facing: coord.Direction)
}

pub type Guard {
  Guard(location: GuardLocation, history: set.Set(GuardLocation))
}

pub type Puzzle {
  Puzzle(map: grid.Grid(MapTile), guard: Guard)
}

type ParsingMapTile {
  ParsingTile(MapTile)
  ParsingGuard(coord.Direction)
}

pub fn parse(input: String) -> Result(Puzzle, String) {
  use puzzle_grid <- result.try(
    grid.from_string(input, with: fn(x) {
      case x {
        "." -> Ok(ParsingTile(Blank))
        "#" -> Ok(ParsingTile(Obstruction))
        "^" -> Ok(ParsingGuard(coord.North))
        ">" -> Ok(ParsingGuard(coord.East))
        "<" -> Ok(ParsingGuard(coord.West))
        "v" -> Ok(ParsingGuard(coord.South))
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
    guard: Guard(location: guard_loc, history: set.from_list([guard_loc])),
  ))
}

// Part 1

type EndState {
  Loop
  OffMap
}

fn move_guard(guard: Guard, to coord: grid.Coordinate) -> Guard {
  let new_loc = GuardLocation(at: coord, facing: guard.location.facing)

  Guard(location: new_loc, history: set.insert(guard.history, new_loc))
}

fn turn_guard(guard: Guard) -> Guard {
  let new_loc =
    GuardLocation(
      at: guard.location.at,
      facing: coord.clockwise(guard.location.facing, for: 2),
    )

  Guard(location: new_loc, history: set.insert(guard.history, new_loc))
}

fn step(map: grid.Grid(MapTile), guard: Guard) -> Result(Guard, EndState) {
  let new_coord = coord.shift(guard.location.at, guard.location.facing)

  case
    set.contains(guard.history, GuardLocation(new_coord, guard.location.facing)),
    grid.get(map, new_coord)
  {
    True, _ -> Error(Loop)
    False, Ok(Blank) -> Ok(move_guard(guard, new_coord))
    False, Ok(Obstruction) -> Ok(turn_guard(guard))
    False, Error(Nil) -> Error(OffMap)
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
  |> set.map(fn(guard) { guard.at })
  |> set.size()
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
    |> set.map(fn(g) { g.at })
    |> set.filter(fn(coord) { coord != input.guard.location.at })

  let n_items = set.size(coordinates_to_search)
  let spin =
    spinner.pulsating_spinner()
    |> spinner.with_left_text("Searching for loops... |")
    |> spinner.with_right_text("| 0/" <> int.to_string(n_items))

  let #(bar, n, _) =
    coordinates_to_search
    |> set.to_list()
    |> list.fold(#(spin, 0, 0), fn(state, coord) {
      let #(spin, n_loops, total) = state
      let spin =
        spinner.tick(spin)
        |> spinner.with_right_text(
          "| " <> int.to_string(total) <> "/" <> int.to_string(n_items),
        )

      spinner.print_spinner(spin)

      case causes_loop(input, coord) {
        True -> #(spin, n_loops + 1, total + 1)
        False -> #(spin, n_loops, total + 1)
      }
    })

  bar |> spinner.finish() |> spinner.print_spinner()

  Ok(n)
}
