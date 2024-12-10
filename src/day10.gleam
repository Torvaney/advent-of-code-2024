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
  set.size(score_trailhead_loop(from: start, in: map))
}

fn score_trailhead_loop(
  from xy: coord.Coordinate,
  in map: grid.Grid(Int),
) -> set.Set(coord.Coordinate) {
  case grid.get(from: map, at: xy) {
    Ok(9) -> set.new() |> set.insert(xy)
    Ok(height) -> {
      next_to(xy)
      |> list.fold(from: set.new(), with: fn(total, adj) {
        case grid.get(from: map, at: adj) {
          Ok(adj_height) if adj_height == height + 1 ->
            set.union(total, score_trailhead_loop(adj, map))
          _ -> total
        }
      })
    }
    Error(_) -> set.new()
  }
}

pub fn next_to(coord: coord.Coordinate) -> List(coord.Coordinate) {
  list.map([coord.North, coord.East, coord.South, coord.West], fn(dir) {
    coord.shift(coord, dir)
  })
}

pub fn solve1(input: Puzzle) -> Result(Int, String) {
  grid.find_all(in: input, with: fn(height) { height == 0 })
  |> list.map(pair.first)
  |> list.map(fn(xy) { score_trailhead(xy, input) })
  |> int.sum()
  |> Ok()
}

// Part 2

pub fn solve2(input: Puzzle) -> Result(Int, String) {
  Error("Part 2 not implemented yet!")
}
