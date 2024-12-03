import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/string

pub type Instruction {
  Mul(Int, Int)
  Do
  Dont
}

pub type Puzzle =
  List(Instruction)

type Buffer {
  Parsing(String)
  ParsedMul0(String)
  ParsedMul1(Int, String)
}

type ParseState {
  ParseState(parsed: Puzzle, buffer: Buffer)
}

fn set_buffer(state: ParseState, to buffer: Buffer) {
  ParseState(parsed: state.parsed, buffer: buffer)
}

fn reset(state: ParseState) {
  ParseState(parsed: state.parsed, buffer: Parsing(""))
}

fn parsed(state: ParseState, instruction: Instruction) {
  ParseState(parsed: [instruction, ..state.parsed], buffer: Parsing(""))
}

fn first_number(state: ParseState, from str: String) {
  case int.parse(str) {
    Ok(x) -> ParseState(parsed: state.parsed, buffer: ParsedMul1(x, ""))
    Error(_) -> reset(state)
  }
}

fn second_number(state: ParseState, num1: Int, from str: String) {
  case int.parse(str) {
    Ok(num2) -> parsed(state, Mul(num1, num2))
    Error(_) -> reset(state)
  }
}

pub fn parse(input: String) -> Result(Puzzle, String) {
  string.to_graphemes(input)
  |> list.fold(
    from: ParseState([], Parsing("")),
    with: fn(state: ParseState, next: String) {
      // NOTE: Would be cleaner as a recursive function, but 🤷‍♂️
      case state.buffer, next, int.parse(next) {
        // mul
        Parsing(""), "m", _ -> set_buffer(state, Parsing("m"))
        Parsing("m"), "u", _ -> set_buffer(state, Parsing("mu"))
        Parsing("mu"), "l", _ -> set_buffer(state, Parsing("mul"))
        Parsing("mul"), "(", _ -> set_buffer(state, ParsedMul0(""))
        // first number
        ParsedMul0(n), ",", _ -> first_number(state, n)
        ParsedMul0(n), _, Ok(_) -> set_buffer(state, ParsedMul0(n <> next))
        ParsedMul0(_), _, Error(_) -> reset(state)
        // second number
        ParsedMul1(n1, n2), ")", _ -> second_number(state, n1, n2)
        ParsedMul1(n1, n2), _, Ok(_) ->
          set_buffer(state, ParsedMul1(n1, n2 <> next))
        ParsedMul1(_, _), _, Error(_) -> reset(state)
        // do
        Parsing(""), "d", _ -> set_buffer(state, Parsing("d"))
        Parsing("d"), "o", _ -> set_buffer(state, Parsing("do"))
        Parsing("do"), "(", _ -> set_buffer(state, Parsing("do("))
        Parsing("do("), ")", _ -> parsed(state, Do)
        // undo
        Parsing("do"), "n", _ -> set_buffer(state, Parsing("don"))
        Parsing("don"), "'", _ -> set_buffer(state, Parsing("don'"))
        Parsing("don'"), "t", _ -> set_buffer(state, Parsing("don't"))
        Parsing("don't"), "(", _ -> set_buffer(state, Parsing("don't("))
        Parsing("don't("), ")", _ -> parsed(state, Dont)
        // Anything else is invalid!
        _, _, _ -> reset(state)
      }
    },
  )
  |> fn(state) { state.parsed }
  |> list.reverse()
  |> Ok()
}

// Part 1

pub fn solve1(input: Puzzle) -> Result(Int, String) {
  input
  |> list.filter_map(fn(instruction) {
    case instruction {
      Mul(a, b) -> Ok(a * b)
      _ -> Error(Nil)
    }
  })
  |> list.reduce(int.add)
  |> result.replace_error("Parsed an empty input!")
}

// Part 2

pub fn solve2(input: Puzzle) -> Result(Int, String) {
  input
  |> list.fold(from: #(0, True), with: fn(state, next_instruction) {
    let #(total, is_enabled) = state
    case is_enabled, next_instruction {
      _, Do -> #(total, True)
      _, Dont -> #(total, False)
      False, Mul(_, _) -> state
      True, Mul(a, b) -> #(total + a * b, True)
    }
  })
  |> pair.first
  |> Ok()
}
