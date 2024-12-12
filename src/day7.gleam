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

type SearchResult(a) {
  Continue(a)
  Complete
  Failed
}

fn depth_first_search(
  with get_next: fn(List(a)) -> SearchResult(List(a)),
) -> Result(List(a), Nil) {
  depth_first_search_loop(from: [], with: get_next)
}

fn depth_first_search_loop(
  from visited: List(a),
  with get_next: fn(List(a)) -> SearchResult(List(a)),
) -> Result(List(a), Nil) {
  case get_next(visited) {
    Complete -> Ok(visited)
    Continue(next) ->
      list.find_map(next, fn(n) {
        depth_first_search_loop(from: [n, ..visited], with: get_next)
      })
    Failed -> Error(Nil)
  }
}

fn equation_can_be_true(eq: Equation, ops: List(Op)) -> Bool {
  let n_ops = list.length({ nonempty.body(eq.1) })
  let res =
    depth_first_search(with: fn(path) {
      case list.length(path) >= n_ops, equation_is_true(eq, path) {
        True, True -> Complete
        False, _ -> Continue(ops)
        True, False -> Failed
      }
    })

  result.is_ok(res)
}

fn solve(input: Puzzle, ops: List(Op)) {
  input
  |> list.filter(fn(x) { equation_can_be_true(x, ops) })
  |> list.map(pair.first)
  |> int.sum()
  |> Ok()
}

pub fn solve1(input: Puzzle) -> Result(Int, String) {
  solve(input, [Mul, Add])
}

// Part 2

pub fn solve2(input: Puzzle) -> Result(Int, String) {
  solve(input, [Mul, Add, Concat])
}
