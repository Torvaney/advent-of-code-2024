import data/nonempty
import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import input

pub type Equation =
  #(Int, nonempty.NonEmpty(Int))

pub type Puzzle =
  List(Equation)

fn parse_equation(input: String) -> Result(Equation, String) {
  input
  |> input.parse_left_right(
    split_on: ": ",
    left_with: int.parse,
    right_with: fn(x) {
      input.parse_list(x, with: int.parse, by: " ")
      |> result.then(nonempty.from_list)
    },
  )
}

pub fn parse(input: String) -> Result(Puzzle, String) {
  input.parse_by_line(input, parse_equation)
}

// Part 1

type Op {
  Mul
  Add
  Concat
}

fn concat(n1: Int, n2: Int) -> Int {
  int.parse(int.to_string(n1) <> int.to_string(n2))
  // Should be impossible!
  |> result.unwrap(or: n2)
}

fn equation_is_true(eq: Equation, ops: List(Op)) -> Bool {
  let #(ans, terms) = eq

  list.zip(ops, nonempty.body(terms))
  |> list.fold(from: nonempty.head(terms), with: fn(total, next) {
    let #(op, val) = next

    case op {
      Mul -> total * val
      Add -> total + val
      Concat -> concat(total, val)
    }
  })
  |> fn(x) { x == ans }
}

fn depth_first_search(
  from current: a,
  with get_next: fn(List(a)) -> List(a),
  until is_end: fn(List(a)) -> Bool,
  after visited: List(a),
) -> Result(List(a), Nil) {
  let new_visited = [current, ..visited]

  case get_next(visited), is_end(new_visited) {
    _, True -> Ok(visited)
    [], _ -> Error(Nil)
    next, False ->
      list.find_map(next, fn(n) {
        depth_first_search(
          from: n,
          with: get_next,
          until: is_end,
          after: new_visited,
        )
      })
  }
}

fn equation_can_be_true(eq: Equation, ops: List(Op)) -> Bool {
  let n_ops = list.length({ nonempty.body(eq.1) })
  let res =
    depth_first_search(
      from: Mul,
      with: fn(prev) {
        case list.length(prev) >= n_ops {
          True -> []
          False -> ops
        }
      },
      until: fn(ops) { equation_is_true(eq, ops) },
      after: [],
    )

  result.is_ok(res)
}

fn solve(input: Puzzle, ops: List(Op)) {
  input
  |> list.filter(fn(x) { equation_can_be_true(x, ops) })
  |> list.map(pair.first)
  |> list.reduce(int.add)
  |> result.replace_error("No equations found!")
}

pub fn solve1(input: Puzzle) -> Result(Int, String) {
  solve(input, [Mul, Add])
}

// Part 2

pub fn solve2(input: Puzzle) -> Result(Int, String) {
  solve(input, [Mul, Add, Concat])
}
