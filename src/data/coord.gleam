import gleam/list

pub type Coordinate =
  #(Int, Int)

pub type Direction {
  NorthWest
  North
  NorthEast
  East
  SouthEast
  South
  SouthWest
  West
}

pub fn shift(from: Coordinate, towards: Direction) -> Coordinate {
  let #(x, y) = from
  case towards {
    // Coordinates are inverted - the top-left is 0-0
    NorthWest -> #(x - 1, y - 1)
    North -> #(x, y - 1)
    NorthEast -> #(x + 1, y - 1)
    East -> #(x + 1, y)
    SouthEast -> #(x + 1, y + 1)
    South -> #(x, y + 1)
    SouthWest -> #(x - 1, y + 1)
    West -> #(x - 1, y)
  }
}

pub fn clockwise(from dir: Direction, for steps: Int) -> Direction {
  list.range(1, steps)
  |> list.fold(from: dir, with: fn(d, _) {
    case d {
      NorthWest -> North
      North -> NorthEast
      NorthEast -> East
      East -> SouthEast
      SouthEast -> South
      South -> SouthWest
      SouthWest -> West
      West -> NorthWest
    }
  })
}

pub fn anticlockwise(from dir: Direction, for steps: Int) -> Direction {
  list.range(1, steps)
  |> list.fold(from: dir, with: fn(d, _) {
    case d {
      NorthWest -> West
      North -> NorthWest
      NorthEast -> North
      East -> NorthEast
      SouthEast -> East
      South -> SouthEast
      SouthWest -> South
      West -> SouthWest
    }
  })
}

pub fn flip(dir: Direction) -> Direction {
  clockwise(dir, 4)
}

pub fn diff(coord1: Coordinate, coord2: Coordinate) -> Coordinate {
  #(coord2.0 - coord1.0, coord2.1 - coord1.1)
}

pub fn move(coord1: Coordinate, by coord2: Coordinate) -> Coordinate {
  #(coord1.0 + coord2.0, coord1.1 + coord2.1)
}
