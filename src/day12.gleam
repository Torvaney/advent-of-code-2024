import data/coord
import data/grid
import gleam/bool
import gleam/int
import gleam/list
import gleam/pair
import gleam/set

pub type Puzzle =
  grid.Grid(String)

pub fn parse(input: String) -> Result(Puzzle, String) {
  grid.from_string(input, Ok)
}

// Part 1

fn count_neighbouring_plots(
  at coord: coord.Coordinate,
  in plot_coords: set.Set(coord.Coordinate),
) -> Int {
  list.count([coord.North, coord.East, coord.West, coord.South], fn(dir) {
    set.contains(plot_coords, coord.shift(coord, dir))
  })
}

fn count_perimeter_sides(
  at coord: coord.Coordinate,
  in plot_coords: set.Set(coord.Coordinate),
) {
  4 - count_neighbouring_plots(coord, plot_coords)
}

fn area_and_perimeter(coords: set.Set(coord.Coordinate)) {
  let area = set.size(coords)
  let perimeter =
    set.to_list(coords)
    |> list.map(fn(xy) { count_perimeter_sides(xy, coords) })
    |> int.sum()

  #(area, perimeter)
}

type PlotGroups =
  List(#(String, set.Set(coord.Coordinate)))

fn group_plots(map: grid.Grid(String)) -> PlotGroups {
  map
  |> grid.to_list()
  |> list.fold(from: #([], set.new()), with: fn(acc, plot) {
    let #(groups, searched) = acc
    let #(coord, group) = plot

    use <- bool.guard(set.contains(searched, coord), #(groups, searched))

    let plot_group =
      find_contiguous_plot(group, coord, map, set.new(), set.new())
    let new_groups = [#(group, plot_group), ..groups]
    let new_searched = set.union(searched, plot_group)

    #(new_groups, new_searched)
  })
  |> pair.first()
}

fn neighbours(
  of group: String,
  from coord: coord.Coordinate,
  in map: grid.Grid(String),
) {
  [coord.North, coord.East, coord.West, coord.South]
  |> list.filter_map(fn(dir) {
    let coord_neighbour = coord.shift(coord, dir)
    case grid.get(map, coord_neighbour) {
      Ok(v) if v == group -> Ok(coord_neighbour)
      _ -> Error(Nil)
    }
  })
  |> set.from_list()
}

fn find_contiguous_plot(
  group: String,
  from coord: coord.Coordinate,
  in map: grid.Grid(String),
  after searched: set.Set(coord.Coordinate),
  followed_by to_search: set.Set(coord.Coordinate),
) {
  let new_neighbours =
    set.difference(from: neighbours(group, coord, map), minus: searched)
  let new_searched = set.insert(searched, coord)

  case set.to_list(new_neighbours), set.to_list(to_search) {
    [], [] -> new_searched
    [], [next, ..rest] ->
      find_contiguous_plot(group, next, map, new_searched, set.from_list(rest))
    [next, ..rest], _ ->
      find_contiguous_plot(
        group,
        next,
        map,
        new_searched,
        set.union(set.from_list(rest), to_search),
      )
  }
}

pub fn solve1(input: Puzzle) -> Result(Int, String) {
  input
  |> group_plots()
  |> list.map(fn(x) {
    let #(area, perimeter) = area_and_perimeter(x.1)
    area * perimeter
  })
  |> int.sum()
  |> Ok()
}

// Part 2

pub fn solve2(input: Puzzle) -> Result(Int, String) {
  Error("Part 2 not implemented yet!")
}
