import data/coord
import data/grid
import gleam/int
import gleam/list
import gleam/result

pub type Puzzle =
  grid.Grid(String)

pub fn parse(input: String) -> Result(Puzzle, String) {
  grid.from_string(input, fn(x) { Ok(x) })
  |> result.replace_error("Could not parse grid!")
}

// Part 1

fn search_xmas(from grid: Puzzle, at coord: coord.Coordinate) -> Int {
  [
    coord.NorthWest,
    coord.North,
    coord.NorthEast,
    coord.East,
    coord.SouthEast,
    coord.South,
    coord.SouthWest,
    coord.West,
  ]
  |> list.filter_map(fn(direction) {
    grid.take_path(from: grid, at: coord, using: list.repeat(direction, 3))
  })
  |> list.filter(fn(items) { items == ["X", "M", "A", "S"] })
  |> list.length()
}

pub fn solve1(input: Puzzle) -> Result(Int, String) {
  grid.coordinates(input)
  |> list.map(fn(coord) { search_xmas(input, coord) })
  |> int.sum()
  |> Ok()
}

// Part 2

fn has_cross_mas(from grid: Puzzle, at coord: coord.Coordinate) -> Bool {
  [coord.NorthWest, coord.NorthEast, coord.SouthWest, coord.SouthEast]
  |> list.filter_map(fn(direction) {
    grid.take_path(
      grid,
      at: coord.shift(coord, coord.flip(direction)),
      using: list.repeat(direction, 2),
    )
  })
  |> list.filter(fn(items) { items == ["M", "A", "S"] })
  |> list.length()
  |> fn(i) { i == 2 }
}

pub fn solve2(input: Puzzle) -> Result(Int, String) {
  grid.coordinates(input)
  |> list.count(fn(coord) { has_cross_mas(input, coord) })
  |> Ok()
}
