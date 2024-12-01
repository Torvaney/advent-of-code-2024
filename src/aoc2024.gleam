import argv
import day1
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

fn day_command(day, parse, solve) -> glint.Command(Nil) {
  use puzzle <- glint.flag(
    glint.bool_flag("puzzle")
    |> glint.flag_default(False)
    |> glint.flag_help("Run on the puzzle input (not the example!)"),
  )

  use debug <- glint.flag(
    glint.bool_flag("debug")
    |> glint.flag_default(False)
    |> glint.flag_help("Debug an error in parsing or solving..."),
  )

  use _, _, flags <- glint.command()
  let assert Ok(puzzle) = puzzle(flags)
  let assert Ok(debug) = debug(flags)

  let solution =
    read_input(day, puzzle)
    |> log_debug("Input", debug)
    |> parse()
    |> log_debug("Parsed:", debug)
    |> result.try(solve)
    |> log_debug("Solved: ", debug)
    |> result.map(int.to_string)

  case solution {
    Ok(answer) -> io.println(answer)
    Error(msg) -> io.println(msg)
  }
}

type Day(a) {
  Day(
    day: Int,
    parse: fn(String) -> Result(a, String),
    solve: fn(a) -> Result(Int, String),
  )
}

fn add_days(cmd: glint.Glint(Nil), days: List(Day(a))) {
  list.fold(over: days, from: cmd, with: fn(c, d) {
    glint.add(c, [int.to_string(d.day)], day_command(d.day, d.parse, d.solve))
  })
}

pub fn main() {
  glint.new()
  |> glint.with_name("Advent of Code, 2024")
  |> glint.pretty_help(glint.default_pretty_help())
  |> add_days([Day(1, day1.parse, day1.solve)])
  |> glint.run(argv.load().arguments)
}
