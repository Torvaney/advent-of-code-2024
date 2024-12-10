import data/coord
import data/grid
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/set

pub type Puzzle =
  grid.Grid(Int)

pub fn parse(input: String) -> Result(Puzzle, String) {
  grid.from_string(input, with: fn(s) {
    int.parse(s)
    |> result.replace_error("Could not parse '" <> s <> "' into string")
  })
}

// Part 1

fn score_trailhead(from start: coord.Coordinate, in map: grid.Grid(Int)) -> Int {
  score_trailhead_loop(from: start, in: map)
  |> list.unique()
  |> list.length()
}

fn score_trailhead_loop(
  from xy: coord.Coordinate,
  in map: grid.Grid(Int),
) -> List(coord.Coordinate) {
  case grid.get(from: map, at: xy) {
    Ok(9) -> [xy]
    Ok(height) -> {
      next_to(xy)
      |> list.fold(from: [], with: fn(total, adj) {
        case grid.get(from: map, at: adj) {
          Ok(adj_height) if adj_height == height + 1 ->
            list.append(score_trailhead_loop(adj, map), total)
          _ -> total
        }
      })
    }
    Error(_) -> []
  }
}

pub fn next_to(coord: coord.Coordinate) -> List(coord.Coordinate) {
  list.map([coord.North, coord.East, coord.South, coord.West], fn(dir) {
    coord.shift(coord, dir)
  })
}

fn solve(
  input: Puzzle,
  fun: fn(coord.Coordinate, Puzzle) -> Int,
) -> Result(Int, String) {
  grid.find_all(in: input, with: fn(height) { height == 0 })
  |> list.map(pair.first)
  |> list.map(fn(xy) { fun(xy, input) })
  |> int.sum()
  |> Ok()
}

pub fn solve1(input: Puzzle) -> Result(Int, String) {
  solve(input, score_trailhead)
}

// Part 2

fn rate_trailhead(from start: coord.Coordinate, in map: grid.Grid(Int)) -> Int {
  score_trailhead_loop(from: start, in: map)
  |> list.length()
}

pub fn solve2(input: Puzzle) -> Result(Int, String) {
  solve(input, rate_trailhead)
}
