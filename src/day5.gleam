import data/graph
import gleam/int
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import input

pub type Path =
  List(Int)

pub type Puzzle {
  Puzzle(graph: graph.DirectedGraph(Int), paths: List(Path))
}

fn parse_edges(input: String) -> Result(set.Set(#(Int, Int)), String) {
  input.parse_by_line(input, fn(line) {
    input.parse_pair(line, split_on: "|", with: int.parse)
  })
  |> result.map(set.from_list)
}

fn parse_paths(input: String) -> Result(List(List(Int)), String) {
  input.parse_by_line(input, fn(line) {
    input.parse_list(line, int.parse)
    |> result.replace_error("Unable to parse Int in list '" <> line <> "'")
  })
}

pub fn parse(input: String) -> Result(Puzzle, String) {
  use chunks <- input.try_with_msg(
    string.split_once(input, "\n\n"),
    "Unable to split input into nodes and edges!",
  )

  let #(edges_input, paths_input) = chunks

  use edges <- result.try(parse_edges(edges_input))
  use paths <- result.try(parse_paths(paths_input))

  Ok(Puzzle(graph: graph.new(from: edges), paths: paths))
}

// Part 1

fn take_middle_element(from list: List(a)) -> Result(a, Nil) {
  case list {
    [x] -> Ok(x)
    [_, x, _] -> Ok(x)
    [] -> Error(Nil)
    [_, _] -> Error(Nil)
    [_, ..rest] -> take_middle_element(list.take(rest, list.length(rest) - 1))
  }
}

pub fn solve1(input: Puzzle) -> Result(Int, String) {
  // map over paths, check if each one is a valid path through the graph
  input.paths
  |> list.filter(fn(path) { graph.is_valid_path(input.graph, path) })
  |> list.try_map(take_middle_element)
  |> result.replace_error("Couldn't take the middle elements of every path!")
  |> result.try(fn(xs) {
    list.reduce(xs, int.add) |> result.replace_error("No valid paths found!")
  })
}

// Part 2

pub fn solve2(input: Puzzle) -> Result(Int, String) {
  Error("Part 2 not implemented yet!")
}
