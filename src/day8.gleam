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

pub fn solve1(input: Puzzle) -> Result(Int, String) {
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
  |> list.filter_map(fn(pair) {
    let #(#(coord1, _), #(coord2, _)) = pair

    let antinode = coord.move(coord2, coord.diff(coord1, coord2))

    case grid.get(input, at: antinode) {
      // Not a valid pair of antennae
      Ok(_) -> Ok(antinode)
      // Not in grid
      Error(Nil) -> Error(Nil)
    }
  })
  |> list.unique()
  |> list.length()
  |> Ok()
}

// Part 2

pub fn solve2(input: Puzzle) -> Result(Int, String) {
  Error("Part 2 not implemented yet!")
}
