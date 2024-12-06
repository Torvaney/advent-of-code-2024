import gleam/dict
import gleam/list
import gleam/result
import gleam/string

// Grid

pub type Coordinate =
  #(Int, Int)

pub opaque type Grid(a) {
  Grid(data: dict.Dict(Coordinate, a))
}

pub fn from_string(str: String) -> Grid(String) {
  let data =
    str
    |> string.split(on: "\n")
    |> list.index_map(fn(row, row_ix) {
      row
      |> string.to_graphemes()
      |> list.index_map(fn(s, col_ix) { #(#(col_ix, row_ix), s) })
    })
    |> list.flatten()
    |> dict.from_list()

  // TODO: validate that all the grid squares are filled...

  Grid(data)
}

// Directions

pub type Direction {
  NorthWest
  North
  NorthEast
  East
  SouthEast
  South
  SouthWest
  West
}

pub fn shift(from: Coordinate, towards: Direction) -> Coordinate {
  let #(x, y) = from
  case towards {
    NorthWest -> #(x - 1, y + 1)
    North -> #(x, y + 1)
    NorthEast -> #(x + 1, y + 1)
    East -> #(x + 1, y)
    SouthEast -> #(x + 1, y - 1)
    South -> #(x, y - 1)
    SouthWest -> #(x - 1, y - 1)
    West -> #(x - 1, y)
  }
}

pub fn clockwise(from dir: Direction, for steps: Int) -> Direction {
  list.range(1, steps)
  |> list.fold(from: dir, with: fn(d, _) {
    case d {
      NorthWest -> North
      North -> NorthEast
      NorthEast -> East
      East -> SouthEast
      SouthEast -> South
      South -> SouthWest
      SouthWest -> West
      West -> NorthWest
    }
  })
}

pub fn flip(dir: Direction) -> Direction {
  clockwise(dir, 4)
}

// Getting values

pub fn get(from grid: Grid(a), at coord: Coordinate) -> Result(a, Nil) {
  dict.get(grid.data, coord)
}

pub fn take_path(
  from grid: Grid(a),
  at coord: Coordinate,
  using steps: List(Direction),
) -> Result(List(a), Nil) {
  list.scan(steps, from: coord, with: fn(xy, dir) { shift(xy, dir) })
  |> list.map(fn(xy) { get(grid, xy) })
  // Append the value at the starting point to the list, too
  |> fn(items) { [get(grid, coord), ..items] }
  |> result.all()
}

pub fn coordinates(from grid: Grid(a)) -> List(Coordinate) {
  dict.keys(grid.data)
}

pub fn values(from grid: Grid(a)) -> List(a) {
  dict.values(grid.data)
}
