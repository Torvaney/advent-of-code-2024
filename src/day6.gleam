import data/grid
import gleam/result
import gleam/set

pub type MapTile {
  Blank
  Obstruction
}

pub type Guard {
  Guard(at: grid.Coordinate, facing: grid.Direction)
}

pub type Puzzle {
  Puzzle(
    map: grid.Grid(MapTile),
    guard: Guard,
    visited: set.Set(grid.Coordinate),
  )
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

  Ok(Puzzle(
    map: grid.map(puzzle_grid, fn(_, val) {
      case val {
        ParsingTile(tile) -> tile
        ParsingGuard(_) -> Blank
      }
    }),
    guard: Guard(at: guard_coord, facing: guard_facing),
    visited: set.from_list([guard_coord]),
  ))
}

// Part 1

fn move_guard(puzzle: Puzzle, to coord: grid.Coordinate) -> Puzzle {
  Puzzle(
    map: puzzle.map,
    guard: Guard(at: coord, facing: puzzle.guard.facing),
    visited: set.insert(puzzle.visited, coord),
  )
}

fn turn_guard(puzzle: Puzzle) -> Puzzle {
  Puzzle(
    map: puzzle.map,
    guard: Guard(
      at: puzzle.guard.at,
      facing: grid.clockwise(puzzle.guard.facing, for: 2),
    ),
    visited: puzzle.visited,
  )
}

fn step(puzzle: Puzzle) -> Result(Puzzle, Nil) {
  let new_coord = grid.shift(puzzle.guard.at, puzzle.guard.facing)

  case grid.get(puzzle.map, new_coord) {
    Ok(Blank) -> Ok(move_guard(puzzle, new_coord))
    Ok(Obstruction) -> Ok(turn_guard(puzzle))
    Error(Nil) -> Error(Nil)
  }
}

fn step_until(puzzle: Puzzle) -> Puzzle {
  case step(puzzle) {
    Ok(stepped) -> step_until(stepped)
    Error(_) -> puzzle
  }
}

pub fn solve1(input: Puzzle) -> Result(Int, String) {
  step_until(input)
  |> fn(puzzle) { puzzle.visited }
  |> set.size()
  |> Ok()
}

// Part 2

pub fn solve2(input: Puzzle) -> Result(Int, String) {
  Error("Part 2 not implemented yet!")
}
