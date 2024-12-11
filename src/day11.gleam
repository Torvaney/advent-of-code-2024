import data/counter
import gleam/dict
import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import input

pub type Stone =
  Int

pub type Puzzle =
  counter.Counter(Stone)

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
  |> result.map(counter.from_list)
}

// Part 1

type StoneTransformations =
  dict.Dict(Stone, List(Stone))

fn split_int(x: Int, power: Int) {
  let factor = list.fold(list.range(1, power), 1, fn(val, _) { 10 * val })
  [x / factor, x - factor * { x / factor }]
}

fn transform_stone(stone: Int) -> List(Stone) {
  let n_digits = string.length(int.to_string(stone))
  case stone, int.is_even(n_digits) {
    0, _ -> [1]
    _, True -> split_int(stone, n_digits / 2)
    _, False -> [stone * 2024]
  }
}

// Not actually required! Was just being paranoid!
fn transform_stone_cached(
  stone: Int,
  cache: StoneTransformations,
) -> #(List(Stone), StoneTransformations) {
  case dict.get(cache, stone) {
    Ok(vals) -> #(vals, cache)
    Error(_) -> {
      let vals = transform_stone(stone)

      #(vals, dict.insert(cache, stone, vals))
    }
  }
}

fn blink(
  stones: counter.Counter(Stone),
  cache: StoneTransformations,
) -> #(counter.Counter(Stone), StoneTransformations) {
  counter.to_list(stones)
  |> list.fold(from: #(stones, cache), with: fn(acc, x) {
    let #(count, cache) = acc
    let #(stone, n) = x
    let #(new_stones, new_cache) = transform_stone_cached(stone, cache)

    let new_count =
      counter.update_by(count, new_stones, by: n)
      |> counter.decrement(stone, by: n)

    #(new_count, new_cache)
  })
}

fn solve(input: Puzzle, n: Int) {
  list.fold(list.range(1, n), #(input, dict.new()), fn(acc, _) {
    blink(acc.0, acc.1)
  })
  |> pair.first()
  |> counter.total()
  |> Ok()
}

pub fn solve1(input: Puzzle) -> Result(Int, String) {
  solve(input, 25)
}

// Part 2

pub fn solve2(input: Puzzle) -> Result(Int, String) {
  solve(input, 75)
}
