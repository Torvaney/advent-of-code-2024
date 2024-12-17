import data/coord
import data/grid
import gleam/dict
import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/set
import gleam/string
import input

pub type MapTile {
  Wall
  Robot
  Empty
  // Part 1
  Box
  // Part 2
  BigBoxL
  BigBoxR
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
  towards dir: coord.Direction,
  from to_search: set.Set(coord.Coordinate),
  after to_move: set.Set(#(coord.Coordinate, MapTile)),
) {
  // Build up a dict of changes
  case set.to_list(to_search) {
    // If we hit an empty square, then all the pieces are free to move;
    // return the changes
    [] -> {
      let old_positions =
        to_move
        |> set.to_list()
        |> list.map(fn(pair) { #(pair.0, Empty) })
        |> dict.from_list()
      let new_positions =
        to_move
        |> set.to_list()
        |> list.map(fn(pair) { #(coord.shift(pair.0, dir), pair.1) })
        |> dict.from_list()

      dict.merge(old_positions, new_positions)
    }
    [coord, ..rest] ->
      case grid.get(map, coord), dir {
        // No changes if we hit a wall, or (somehow) go off-grid
        Ok(Wall), _ -> dict.new()

        // If we hit an empty space, then we're all good.
        // We don't need to move this piece. Don't add anything and continue.
        Ok(Empty), _ | Error(_), _ ->
          get_shifted_tiles(
            in: map,
            from: set.from_list(rest),
            towards: dir,
            after: to_move,
          )

        // If we hit a box or robot, add the coord to the set and continue
        Ok(Box as tile), _
        | Ok(Robot as tile), _
        | Ok(tile), coord.East
        | Ok(tile), coord.West
        ->
          get_shifted_tiles(
            in: map,
            from: set.from_list([coord.shift(coord, dir), ..rest]),
            towards: dir,
            after: set.insert(to_move, #(coord, tile)),
          )

        // Part 2...
        Ok(BigBoxL), _ ->
          get_shifted_tiles(
            in: map,
            towards: dir,
            from: set.difference(
              set.from_list([
                coord.shift(coord, dir),
                coord.shift(coord, coord.East),
                ..rest
              ]),
              set.map(to_move, pair.first),
            ),
            after: to_move
              |> set.insert(#(coord, BigBoxL)),
          )
        Ok(BigBoxR), _ ->
          get_shifted_tiles(
            in: map,
            towards: dir,
            from: set.difference(
              set.from_list([
                coord.shift(coord, dir),
                coord.shift(coord, coord.West),
                ..rest
              ]),
              set.map(to_move, pair.first),
            ),
            after: to_move
              |> set.insert(#(coord, BigBoxR)),
          )
      }
  }
}

fn apply_instruction(map: grid.Grid(MapTile), instruction: coord.Direction) {
  use #(robot, _) <- result.try(grid.find(map, fn(x) { x == Robot }))
  let changes =
    get_shifted_tiles(
      in: map,
      from: set.from_list([robot]),
      towards: instruction,
      after: set.new(),
    )

  grid.debug(map, fn(m) {
    case m {
      Wall -> "#"
      Robot -> "@"
      Box -> "O"
      BigBoxL -> "["
      BigBoxR -> "]"
      _ -> "."
    }
  })

  Ok(grid.update(in: map, with: changes))
}

fn total_gps(map: grid.Grid(MapTile)) -> Int {
  map
  |> grid.find_all(fn(x) { x == Box || x == BigBoxL })
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

fn double_widths(map) {
  map
  |> grid.to_list()
  |> list.flat_map(fn(tile) {
    let #(#(x, y), val) = tile

    case val {
      Robot -> [#(#(x * 2, y), Robot)]
      Box -> [#(#(x * 2, y), BigBoxL), #(#({ x * 2 } + 1, y), BigBoxR)]
      _ -> [#(#(x * 2, y), val), #(#({ x * 2 } + 1, y), val)]
    }
  })
  |> grid.from_list()
}

pub fn solve2(input: Puzzle) -> Result(Int, String) {
  list.try_fold(input.instructions, double_widths(input.map), apply_instruction)
  |> result.replace_error("Could not find robot in map!")
  |> result.map(fn(x) {
    grid.debug(x, fn(m) {
      case m {
        Wall -> "#"
        Robot -> "@"
        Box -> "O"
        BigBoxL -> "["
        BigBoxR -> "]"
        _ -> "."
      }
    })
  })
  |> result.map(total_gps)
}
