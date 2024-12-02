import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/result
import gleam/string
import input

pub type Level =
  Int

// NB: Could enforce the fact that there are exactly 6...
pub type Report =
  List(Level)

pub type Puzzle =
  List(Report)

fn parse_row(input: String) -> Result(Report, String) {
  string.split(input, " ")
  |> list.try_map(int.parse)
  |> result.replace_error("Failed to parse row: '" <> input <> "'")
}

pub fn parse(input: String) -> Result(Puzzle, String) {
  input.parse_by_line(input, parse_row)
}

// Part 1

type LevelDifference {
  Zero
  Asc
  Desc
  TooLarge
}

fn categorise_level(pair: #(Level, Level)) -> LevelDifference {
  case int.compare(pair.0, pair.1), int.absolute_value(pair.1 - pair.0) <= 3 {
    order.Eq, _ -> Zero
    order.Lt, True -> Asc
    order.Gt, True -> Desc
    _, False -> TooLarge
  }
}

fn all_ascending_or_descending(diffs: List(LevelDifference)) {
  case list.unique(diffs) {
    [Asc] -> True
    [Desc] -> True
    _ -> False
  }
}

fn is_safe(report: Report) {
  list.window_by_2(report)
  |> list.map(categorise_level)
  |> all_ascending_or_descending()
}

pub fn solve1(input: Puzzle) -> Result(Int, String) {
  Ok(list.count(input, is_safe))
}

// Part 2

pub fn solve2(input: Puzzle) -> Result(Int, String) {
  Error("Part 2 not implemented yet!")
}
