import argv
import day1
import day2
import day3
import day4
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import glint
import simplifile

fn input_path(day: Int, puzzle: Bool) -> String {
  case puzzle {
    True -> "./inputs/day" <> int.to_string(day) <> "/puzzle.txt"
    False -> "./inputs/day" <> int.to_string(day) <> "/example.txt"
  }
}

fn read_input(day: Int, puzzle: Bool) -> String {
  let assert Ok(input) = simplifile.read(input_path(day, puzzle))
  input
}

fn log_debug(a: a, msg: String, show: Bool) -> a {
  case show {
    True -> {
      io.print(msg <> ": ")
      io.debug(a)
      a
    }
    False -> a
  }
}

type Day {
  Day(
    index: Int,
    solve1: fn(String, Bool) -> Result(String, String),
    solve2: fn(String, Bool) -> Result(String, String),
  )
}

fn day(
  index: Int,
  parse: fn(String) -> Result(a, String),
  solve1: fn(a) -> Result(Int, String),
  solve2: fn(a) -> Result(Int, String),
) -> Day {
  Day(
    index: index,
    solve1: fn(input, debug) {
      input
      |> log_debug("Input", debug)
      |> parse
      |> log_debug("Parsed", debug)
      |> result.then(solve1)
      |> log_debug("Solved", debug)
      |> result.map(int.to_string)
    },
    solve2: fn(input, debug) {
      input
      |> log_debug("Input", debug)
      |> parse
      |> log_debug("Parsed", debug)
      |> result.then(solve2)
      |> log_debug("Solved", debug)
      |> result.map(int.to_string)
    },
  )
}

fn solve_fn(day: Day, part2: Bool) {
  case part2 {
    True -> day.solve2
    False -> day.solve1
  }
}

fn day_command(day: Day) -> glint.Command(Nil) {
  use debug <- glint.flag(
    glint.bool_flag("debug")
    |> glint.flag_default(False)
    |> glint.flag_help("Debug an error in parsing or solving..."),
  )
  use puzzle <- glint.flag(
    glint.bool_flag("puzzle")
    |> glint.flag_default(False)
    |> glint.flag_help("Run on the puzzle input (not the example!)"),
  )
  use part2 <- glint.flag(
    glint.bool_flag("two")
    |> glint.flag_default(False)
    |> glint.flag_help("Part Two!"),
  )

  use _, _, flags <- glint.command()
  let assert Ok(debug) = debug(flags)
  let assert Ok(puzzle) = puzzle(flags)
  let assert Ok(part2) = part2(flags)

  let solution =
    read_input(day.index, puzzle)
    |> solve_fn(day, part2)(debug)

  case solution {
    Ok(answer) -> io.println(answer)
    Error(msg) -> io.println(msg)
  }
}

fn add_days(cmd: glint.Glint(Nil), days: List(Day)) {
  list.fold(over: days, from: cmd, with: fn(c, d) {
    glint.add(c, [int.to_string(d.index)], day_command(d))
  })
}

pub fn main() {
  glint.new()
  |> glint.with_name("Advent of Code, 2024")
  |> glint.pretty_help(glint.default_pretty_help())
  |> add_days([
    day(1, day1.parse, day1.solve1, day1.solve2),
    day(2, day2.parse, day2.solve1, day2.solve2),
    day(3, day3.parse, day3.solve1, day3.solve2),
    day(4, day4.parse, day4.solve1, day4.solve2),
  ])
  |> glint.run(argv.load().arguments)
}
