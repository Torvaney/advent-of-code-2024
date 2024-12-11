import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import input

pub type Puzzle =
  List(Int)

pub fn parse(input: String) -> Result(Puzzle, String) {
  input
  |> string.trim()
  |> input.parse_list(
    fn(s) {
      int.parse(s)
      |> result.replace_error("Could not parse '" <> s <> "' into Int")
    },
    " ",
  )
}

// Part 1

fn split_int(x: Int, power: Int) {
  let factor = list.fold(list.range(1, power), 1, fn(val, _) { 10 * val })
  [x / factor, x - factor * { x / factor }]
}

fn transform_stone(stone: Int) {
  let n_digits = string.length(int.to_string(stone))
  case stone, int.is_even(n_digits) {
    0, _ -> [1]
    _, True -> split_int(stone, n_digits / 2)
    _, False -> [stone * 2024]
  }
}

fn blink(stones) {
  stones |> list.flat_map(transform_stone)
}

pub fn solve1(input: Puzzle) -> Result(Int, String) {
  list.fold(list.range(1, 25), input, fn(stones, _) { blink(stones) })
  |> list.length()
  |> Ok()
}

// Part 2

pub fn solve2(input: Puzzle) -> Result(Int, String) {
  Error("Part 2 not implemented yet!")
}
