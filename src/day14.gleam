import data/coord
import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/regexp
import gleam/result
import gleam/set
import gleam/string
import input

pub type Robot {
  Robot(position: coord.Coordinate, velocity: coord.Coordinate)
}

pub type Puzzle =
  List(Robot)

fn parse_robot_coord(input: String) {
  let error_msg = "Unable to parse coords from '" <> input <> "'"
  let assert Ok(re) = regexp.from_string("(p|v)=(.*)")

  case regexp.scan(re, input) {
    [match] -> {
      case match.submatches {
        [_, Some(m)] ->
          coord.from_string(m, ",") |> result.replace_error(error_msg)
        _ -> Error(error_msg)
      }
    }
    _ -> Error(error_msg)
  }
}

fn parse_robot(input: String) {
  use #(pos, vel) <- result.try(input.parse_pair(
    input,
    split_on: " ",
    with: parse_robot_coord,
  ))

  Ok(Robot(pos, vel))
}

pub fn parse(input: String) -> Result(Puzzle, String) {
  input.parse_by_line(input, parse_robot)
}

// Part 1

fn move_axis(from x: Int, by dx: Int, for steps: Int, up_to max: Int) -> Int {
  let assert Ok(next) = int.modulo({ x + { { max + dx } * steps } }, max)
  next
}

fn move_robot(robot: Robot, steps: Int, bounds: coord.Coordinate) -> Robot {
  // Move robot `steps` steps, wrapping at `bounds`
  let #(px, py) = robot.position
  let #(vx, vy) = robot.velocity
  let #(bx, by) = bounds

  Robot(
    #(move_axis(px, vx, steps, bx), move_axis(py, vy, steps, by)),
    robot.velocity,
  )
}

pub fn solve1(input: Puzzle) -> Result(Int, String) {
  // NB: only for puzzle input!
  let grid_size = #(101, 103)
  let mid_x = { grid_size.0 - 1 } / 2
  let mid_y = { grid_size.1 - 1 } / 2

  input
  |> list.map(fn(r) { move_robot(r, 100, grid_size) })
  // Remove robots at halfway
  |> list.filter(fn(r) {
    bool.and(r.position.0 != mid_x, r.position.1 != mid_y)
  })
  // Group by quadrants
  |> list.group(by: fn(r) { #(r.position.0 > mid_x, r.position.1 > mid_y) })
  |> dict.map_values(fn(_, robots) { list.length(robots) })
  // Get total
  |> dict.values()
  |> int.product()
  |> Ok()
}

// Part 2

type IndexedPuzzle {
  IndexedPuzzle(step: Int, robots: List(Robot), occupied: Int)
}

fn count_occupied(robots: List(Robot)) {
  list.map(robots, fn(r) { r.position }) |> set.from_list() |> set.size()
}

fn show_grid(robots: List(Robot), grid: #(Int, Int)) {
  let coords = list.map(robots, fn(r) { r.position }) |> set.from_list()

  list.map(list.range(0, grid.0 - 1), fn(y) {
    list.map(list.range(0, grid.1 - 1), fn(x) {
      case set.contains(coords, #(x, y)) {
        True -> "0"
        False -> " "
      }
    })
    |> string.concat()
  })
  |> list.intersperse(with: "\n")
  |> string.concat()
  |> io.println()

  robots
}

pub fn solve2(input: Puzzle) -> Result(Int, String) {
  let grid_size = #(101, 103)

  let steps =
    list.scan(
      list.range(0, 10_000),
      IndexedPuzzle(0, input, count_occupied(input)),
      fn(ip, i) {
        let robots = list.map(ip.robots, fn(r) { move_robot(r, 1, grid_size) })
        IndexedPuzzle(
          step: i + 1,
          robots: robots,
          occupied: count_occupied(robots),
        )
      },
    )

  // Christmas tree arrangement ought(?) to have more(?) blank spaces than others
  // (NB: it turns out we just needed to take the top one...)
  steps
  |> list.sort(by: fn(ip1, ip2) { int.compare(ip1.occupied, ip2.occupied) })
  |> list.reverse()
  |> list.take(up_to: 10)
  |> list.map(fn(ip) {
    io.println("Step " <> int.to_string(ip.step))
    io.println("Occupied: " <> int.to_string(ip.occupied))
    show_grid(ip.robots, grid_size)
    io.println(string.repeat("-", grid_size.0))

    ip.step
  })
  |> list.first()
  // Impossible...
  |> result.replace_error(
    "No steps found - did you configure the search correctly?",
  )
}
