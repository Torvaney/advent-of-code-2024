import data/grid
import gleam/int
import gleam/list
import gleam/result

pub type Puzzle =
  grid.Grid(String)

pub fn parse(input: String) -> Result(Puzzle, String) {
  Ok(grid.from_string(input))
}

// Part 1

fn search_xmas(from grid: Puzzle, at coord: grid.Coordinate) -> Int {
  [
    grid.NorthWest,
    grid.North,
    grid.NorthEast,
    grid.East,
    grid.SouthEast,
    grid.South,
    grid.SouthWest,
    grid.West,
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
  |> list.reduce(int.add)
  |> result.unwrap(0)
  |> Ok()
}

// Part 2

fn has_cross_mas(from grid: Puzzle, at coord: grid.Coordinate) -> Bool {
  [grid.NorthWest, grid.NorthEast, grid.SouthWest, grid.SouthEast]
  |> list.filter_map(fn(direction) {
    grid.take_path(
      grid,
      at: grid.shift(coord, grid.flip(direction)),
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
