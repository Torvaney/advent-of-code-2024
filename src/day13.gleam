import data/coord
import gleam/bool
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/regexp
import gleam/result
import gleam/string
import input

pub type Machine {
  Machine(a: coord.Coordinate, b: coord.Coordinate, prize: coord.Coordinate)
}

pub type Puzzle =
  List(Machine)

fn parse_int(x: String) {
  int.parse(x) |> result.replace_error("Could not parse Int from '" <> x <> "'")
}

fn parse_coord(x: String, y: String) {
  use x <- result.try(parse_int(x))
  use y <- result.try(parse_int(y))
  Ok(#(x, y))
}

fn parse_xy(input: String, re: regexp.Regexp) -> Result(#(Int, Int), String) {
  case regexp.scan(re, input) {
    [match] -> {
      case match.submatches {
        [Some(x), Some(y)] -> parse_coord(x, y)
        _ -> Error("Unable to parse coords from '" <> input <> "'")
      }
    }
    _ -> Error("Unable to parse coords from '" <> input <> "'")
  }
}

fn parse_button(input: String) -> Result(#(Int, Int), String) {
  let assert Ok(re_button) =
    regexp.from_string("Button .: X\\+(\\d+), Y\\+(\\d+)")

  parse_xy(input, re_button)
}

fn parse_prize(input: String) -> Result(#(Int, Int), String) {
  let assert Ok(re_prize) = regexp.from_string("Prize: X\\=(\\d+), Y\\=(\\d+)")
  parse_xy(input, re_prize)
}

fn parse_block(input: String) -> Result(Machine, String) {
  case string.split(input, "\n") {
    [a, b, prize] -> {
      use button_a <- result.try(parse_button(a))
      use button_b <- result.try(parse_button(b))
      use prize_xy <- result.try(parse_prize(prize))

      Ok(Machine(button_a, button_b, prize_xy))
    }
    _ -> Error("Invalid input for block: '" <> input <> "'")
  }
}

pub fn parse(input: String) -> Result(Puzzle, String) {
  input
  |> string.trim()
  |> input.parse_list(parse_block, by: "\n\n")
}

// Part 1

fn solve_machine(machine: Machine) {
  let #(a_x, a_y) = machine.a
  let #(b_x, b_y) = machine.b
  let #(p_x, p_y) = machine.prize

  // Solve simultaneous equations via Cramer's rule
  let determinant = a_x * b_y - a_y * b_x
  use <- bool.guard(
    determinant == 0,
    Error("Not one single solution! (E.g. parallel lines)"),
  )

  let a_presses = { p_x * b_y - p_y * b_x } / determinant
  let b_presses = { a_x * p_y - a_y * p_x } / determinant

  // Check for a non-integer solution
  // (we can be lazy and just abuse the fact that due to integer division,
  //  a non-int solution will not return the exact prize when passed through the
  //  original equation)
  let check_x = a_presses * a_x + b_presses * b_x
  let check_y = a_presses * a_y + b_presses * b_y
  use <- bool.guard(
    bool.or(check_x != p_x, check_y != p_y),
    Error("No integer solution found!"),
  )

  // Check for any solutions that are invalid due to negative presses
  // (at this point, it would have been cleaner to use linear programming!)
  use <- bool.guard(
    bool.or(a_presses < 0, b_presses < 0),
    Error("No positive solution found!"),
  )

  Ok(#(a_presses, b_presses))
}

pub fn solve1(input: Puzzle) -> Result(Int, String) {
  input
  |> list.filter_map(fn(m) {
    use #(a, b) <- result.try(solve_machine(m))
    Ok(3 * a + 1 * b)
  })
  |> int.sum()
  |> Ok()
}

// Part 2

fn add_offset(machine: Machine) -> Machine {
  let offset = 10_000_000_000_000
  let #(x, y) = machine.prize

  Machine(machine.a, machine.b, #(x + offset, y + offset))
}

pub fn solve2(input: Puzzle) -> Result(Int, String) {
  input
  |> list.filter_map(fn(m) {
    use #(a, b) <- result.try(solve_machine(add_offset(m)))
    Ok(3 * a + 1 * b)
  })
  |> int.sum()
  |> Ok()
}
