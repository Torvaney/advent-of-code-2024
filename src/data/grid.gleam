import data/coord
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string

// Grid

pub type Coordinate =
  #(Int, Int)

pub opaque type Grid(a) {
  Grid(data: dict.Dict(coord.Coordinate, a))
}

pub fn from_string(
  str: String,
  with parse: fn(String) -> Result(a, err),
) -> Result(Grid(a), err) {
  str
  |> string.split(on: "\n")
  |> list.index_map(fn(row, row_ix) {
    row
    |> string.to_graphemes()
    |> list.index_map(fn(s, col_ix) { #(#(col_ix, row_ix), s) })
  })
  |> list.flatten()
  |> list.try_map(with: fn(item) {
    parse(item.1) |> result.map(fn(x) { #(item.0, x) })
  })
  |> result.map(dict.from_list)
  |> result.map(Grid)
  // TODO: validate that all the grid squares are filled...
}

pub fn from_list(items: List(#(coord.Coordinate, a))) -> Grid(a) {
  Grid(dict.from_list(items))
}

pub fn to_list(grid: Grid(a)) -> List(#(coord.Coordinate, a)) {
  dict.to_list(grid.data)
}

// Getting values

pub fn get(from grid: Grid(a), at coord: coord.Coordinate) -> Result(a, Nil) {
  dict.get(grid.data, coord)
}

pub fn take_path(
  from grid: Grid(a),
  at coord: coord.Coordinate,
  using steps: List(coord.Direction),
) -> Result(List(a), Nil) {
  list.scan(steps, from: coord, with: fn(xy, dir) { coord.shift(xy, dir) })
  |> list.map(fn(xy) { get(grid, xy) })
  // Append the value at the starting point to the list, too
  |> fn(items) { [get(grid, coord), ..items] }
  |> result.all()
}

pub fn coordinates(from grid: Grid(a)) -> List(coord.Coordinate) {
  dict.keys(grid.data)
}

pub fn values(from grid: Grid(a)) -> List(a) {
  dict.values(grid.data)
}

pub fn find(
  in grid: Grid(a),
  with fun: fn(a) -> Bool,
) -> Result(#(coord.Coordinate, a), Nil) {
  dict.to_list(grid.data)
  |> list.find(fn(item) { fun(item.1) })
}

pub fn find_map(
  in grid: Grid(a),
  with fun: fn(a) -> Result(b, c),
) -> Result(#(coord.Coordinate, b), Nil) {
  dict.to_list(grid.data)
  |> list.find_map(fn(item) {
    fun(item.1) |> result.map(fn(x) { #(item.0, x) })
  })
}

pub fn find_all(
  in grid: Grid(a),
  with fun: fn(a) -> Bool,
) -> List(#(coord.Coordinate, a)) {
  dict.to_list(grid.data)
  |> list.filter(fn(item) { fun(item.1) })
}

pub fn find_all_map(
  in grid: Grid(a),
  with fun: fn(a) -> Result(b, c),
) -> List(#(coord.Coordinate, b)) {
  dict.to_list(grid.data)
  |> list.filter_map(fn(item) {
    fun(item.1) |> result.map(fn(x) { #(item.0, x) })
  })
}

// Transformations

pub fn map(
  over grid: Grid(a),
  with fun: fn(coord.Coordinate, a) -> b,
) -> Grid(b) {
  Grid(data: dict.map_values(grid.data, fun))
}

pub fn set(in grid: Grid(a), at coord: coord.Coordinate, to val: a) -> Grid(a) {
  Grid(data: dict.insert(grid.data, coord, val))
}

pub fn update(
  in grid: Grid(a),
  with changes: dict.Dict(coord.Coordinate, a),
) -> Grid(a) {
  Grid(data: dict.merge(into: grid.data, from: changes))
}

// Debug

pub fn debug(grid: Grid(a), with to_string: fn(a) -> String) {
  let #(max_x, max_y) =
    dict.keys(grid.data)
    |> list.fold(#(0, 0), fn(max, coord) {
      #(int.max(max.0, coord.0), int.max(max.1, coord.1))
    })

  list.map(list.range(0, max_y - 1), fn(y) {
    list.map(list.range(0, max_x - 1), fn(x) {
      case get(grid, #(x, y)) {
        Ok(v) -> to_string(v)
        Error(Nil) -> " "
      }
    })
    |> string.concat()
  })
  |> list.intersperse(with: "\n")
  |> string.concat()
  |> io.println()

  grid
}
