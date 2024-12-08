import data/coord
import data/grid
import gleam/bool
import gleam/list
import gleam_community/maths/combinatorics

pub type MapTile {
  Empty
  Antenna(String)
}

pub type Puzzle =
  grid.Grid(MapTile)

pub fn parse(input: String) -> Result(Puzzle, String) {
  grid.from_string(input, with: fn(s) {
    case s {
      "." -> Ok(Empty)
      v -> Ok(Antenna(v))
    }
  })
}

// Part 1

type AntennaCoord =
  #(coord.Coordinate, String)

fn solve(
  input: Puzzle,
  with find_antinodes: fn(#(AntennaCoord, AntennaCoord)) ->
    List(coord.Coordinate),
) {
  let antennae =
    grid.find_all_map(in: input, with: fn(x) {
      case x {
        Empty -> Error(Nil)
        Antenna(x) -> Ok(x)
      }
    })

  combinatorics.cartesian_product(antennae, antennae)
  |> list.filter(fn(pair) {
    let #(#(coord1, val1), #(coord2, val2)) = pair

    bool.and(val1 == val2, coord1 != coord2)
  })
  |> list.flat_map(find_antinodes)
  |> list.unique()
  |> list.length()
  |> Ok()
}

pub fn solve1(input: Puzzle) -> Result(Int, String) {
  solve(input, fn(pair) {
    let #(#(coord1, _), #(coord2, _)) = pair

    let antinode = coord.move(coord2, coord.diff(coord1, coord2))

    case grid.get(input, at: antinode) {
      Ok(_) -> [antinode]
      // Not in grid
      Error(Nil) -> []
    }
  })
}

// Part 2

fn move_until_off_map(
  in map: Puzzle,
  from start: coord.Coordinate,
  by diff: coord.Coordinate,
  after prev: List(coord.Coordinate),
) -> List(coord.Coordinate) {
  let antinode = coord.move(start, diff)

  case grid.get(map, antinode) {
    Ok(_) -> move_until_off_map(map, antinode, diff, [antinode, ..prev])
    // Not in grid
    Error(Nil) -> prev
  }
}

pub fn solve2(input: Puzzle) -> Result(Int, String) {
  solve(input, fn(pair) {
    let #(#(coord1, _), #(coord2, _)) = pair

    move_until_off_map(
      in: input,
      from: coord2,
      by: coord.diff(coord1, coord2),
      after: [coord2],
    )
  })
}
