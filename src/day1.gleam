import gleam/int
import gleam/list
import gleam/result
import input

pub type Puzzle =
  List(#(Int, Int))

pub fn parse(input: String) -> Result(Puzzle, String) {
  input.parse_by_line(input, with: fn(s) {
    input.parse_pair(s, split_on: "   ", with: int.parse)
  })
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
