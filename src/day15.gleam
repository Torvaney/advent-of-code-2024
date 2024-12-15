import data/coord
import data/grid
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import input

pub type MapTile {
  Wall
  Robot
  Box
  Empty
}

pub type Puzzle {
  Puzzle(map: grid.Grid(MapTile), instructions: List(coord.Direction))
}

fn parse_tile(x: String) {
  case x {
    "#" -> Ok(Wall)
    "@" -> Ok(Robot)
    "O" -> Ok(Box)
    "." -> Ok(Empty)
    other -> Error("Unable to parse '" <> other <> "' into map tile!")
  }
}

fn parse_instructions(input: String) {
  string.split(input, "\n")
  |> string.concat()
  |> string.to_graphemes()
  |> list.try_map(fn(x) {
    case x {
      "v" -> Ok(coord.South)
      "^" -> Ok(coord.North)
      ">" -> Ok(coord.East)
      "<" -> Ok(coord.West)
      other -> Error("Unable to parse '" <> other <> "' into direction!")
    }
  })
}

pub fn parse(input: String) -> Result(Puzzle, String) {
  use #(map, instructions) <- result.try(input.parse_left_right(
    input,
    split_on: "\n\n",
    left_with: fn(x) { grid.from_string(x, parse_tile) },
    right_with: parse_instructions,
  ))

  Ok(Puzzle(map: map, instructions: instructions))
}

// Part 1

fn get_shifted_tiles(
  in map: grid.Grid(MapTile),
  with tile: MapTile,
  at coord: coord.Coordinate,
  towards dir: coord.Direction,
  after changes: dict.Dict(coord.Coordinate, MapTile),
) {
  // Build up a dict of changes
  case grid.get(map, coord) {
    // No changes if we hit a wall, or (somehow) go off-grid
    Ok(Wall) -> dict.new()
    Error(_) -> dict.new()
    // If we hit an empty square, then all the pieces are free to move;
    // return the changes
    Ok(Empty) -> dict.insert(changes, coord, tile)
    // If we hit a box or robot, move the previous box or robot into the current
    // square and continue
    Ok(box_or_robot) ->
      get_shifted_tiles(
        in: map,
        with: box_or_robot,
        at: coord.shift(coord, dir),
        towards: dir,
        after: dict.insert(changes, coord, tile),
      )
  }
}

fn apply_instruction(map: grid.Grid(MapTile), instruction: coord.Direction) {
  use #(robot, _) <- result.try(grid.find(map, fn(x) { x == Robot }))
  let changes =
    get_shifted_tiles(
      in: map,
      with: Empty,
      at: robot,
      towards: instruction,
      after: dict.new(),
    )
  Ok(grid.update(in: map, with: changes))
}

fn total_gps(map: grid.Grid(MapTile)) -> Int {
  map
  |> grid.find_all(fn(x) { x == Box })
  |> list.map(fn(pair) {
    let #(x, y) = pair.0
    x + 100 * y
  })
  |> int.sum()
}

pub fn solve1(input: Puzzle) -> Result(Int, String) {
  list.try_fold(input.instructions, input.map, apply_instruction)
  // Should never happen! Should think about a `zipper`-style grid to make this
  // impossible...
  |> result.replace_error("Could not find robot in map!")
  |> result.map(fn(x) {
    grid.debug(x, fn(m) {
      case m {
        Wall -> "#"
        Robot -> "@"
        Box -> "O"
        _ -> "."
      }
    })
  })
  |> result.map(total_gps)
}

// Part 2

pub fn solve2(input: Puzzle) -> Result(Int, String) {
  Error("Part 2 not implemented yet!")
}
