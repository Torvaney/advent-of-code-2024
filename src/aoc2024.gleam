import argv
import day1
import day10
import day11
import day12
import day13
import day14
import day15
import day2
import day3
import day4
import day5
import day6
import day7
import day8
import day9
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
    day(5, day5.parse, day5.solve1, day5.solve2),
    day(6, day6.parse, day6.solve1, day6.solve2),
    day(7, day7.parse, day7.solve1, day7.solve2),
    day(8, day8.parse, day8.solve1, day8.solve2),
    day(9, day9.parse, day9.solve1, day9.solve2),
    day(10, day10.parse, day10.solve1, day10.solve2),
    day(11, day11.parse, day11.solve1, day11.solve2),
    day(12, day12.parse, day12.solve1, day12.solve2),
    day(13, day13.parse, day13.solve1, day13.solve2),
    day(14, day14.parse, day14.solve1, day14.solve2),
    day(15, day15.parse, day15.solve1, day15.solve2),
  ])
  |> glint.run(argv.load().arguments)
}
