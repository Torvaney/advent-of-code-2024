import gleam/int
import gleam/list
import gleam/order
import gleam/pair
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

fn all_ascending_or_descending(diffs: List(LevelDifference)) -> Bool {
  case list.unique(diffs) {
    [Asc] -> True
    [Desc] -> True
    _ -> False
  }
}

fn is_safe(report: Report) -> Bool {
  list.window_by_2(report)
  |> list.map(categorise_level)
  |> all_ascending_or_descending()
}

pub fn solve1(input: Puzzle) -> Result(Int, String) {
  Ok(list.count(input, is_safe))
}

// Part 2

fn drop_nth(over list: List(a), at n: Int) -> List(a) {
  list.zip(list.range(0, list.length(list)), list)
  |> list.filter(fn(xy) { xy.0 != n })
  |> list.map(pair.second)
}

fn is_safe_with_problem_dampener(report: Report) {
  list.range(0, list.length(report))
  |> list.map(fn(i) { drop_nth(report, i) })
  |> list.any(is_safe)
}

pub fn solve2(input: Puzzle) -> Result(Int, String) {
  Ok(list.count(input, is_safe_with_problem_dampener))
}
