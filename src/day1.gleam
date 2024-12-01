import gleam/int
import gleam/list
import gleam/result
import gleam/string

fn try_with_msg(
  result: Result(a, Nil),
  msg: String,
  apply fun: fn(a) -> Result(b, String),
) -> Result(b, String) {
  result.try(result |> result.replace_error(msg), apply: fun)
}

fn parse_row(input_row: String) -> Result(#(Int, Int), String) {
  use nums <- try_with_msg(
    string.split_once(input_row, "   "),
    "Failed to split row: '" <> input_row <> "'",
  )

  let #(s1, s2) = nums

  use int1 <- try_with_msg(
    int.parse(s1),
    "Failed to parse: '" <> s1 <> "' to `Int`",
  )
  use int2 <- try_with_msg(
    int.parse(s2),
    "Failed to parse: '" <> s2 <> "' to `Int`",
  )

  Ok(#(int1, int2))
}

pub type Puzzle =
  List(#(Int, Int))

pub fn parse(input: String) -> Result(Puzzle, String) {
  string.split(input, "\n")
  |> list.filter(fn(x) { !string.is_empty(x) })
  |> list.try_map(parse_row)
}

// Part 1

pub fn solve1(input: Puzzle) -> Result(Int, String) {
  let #(i1, i2) = list.unzip(input)

  list.zip(list.sort(i1, by: int.compare), list.sort(i2, int.compare))
  |> list.map(fn(pair) { int.absolute_value(pair.0 - pair.1) })
  |> list.reduce(with: int.add)
  // NOTE: could raise this error in parsing
  |> result.replace_error("Parsed an empty input!")
}

// Part 2

fn similarity_score(x: Int, xs: List(Int)) -> Int {
  list.filter(xs, fn(xi) { xi == x })
  |> list.length()
  |> int.multiply(x)
}

pub fn solve2(input: Puzzle) -> Result(Int, String) {
  let #(i1, i2) = list.unzip(input)

  list.map(i1, fn(x) { similarity_score(x, i2) })
  |> list.reduce(with: int.add)
  |> result.replace_error("Parsed an empty input!")
}
