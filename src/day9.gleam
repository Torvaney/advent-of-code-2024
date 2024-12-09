import gleam/int
import gleam/list
import gleam/order
import gleam/result
import gleam/string

pub type DiskSpace {
  DiskFile(id: Int, size: Int)
  DiskFree(size: Int)
}

pub type DiskMap =
  List(DiskSpace)

pub type Puzzle =
  DiskMap

pub fn parse(input: String) -> Result(Puzzle, String) {
  string.to_graphemes(input)
  |> list.filter(fn(x) { x != "\n" })
  |> list.index_map(fn(x, i) {
    case int.is_even(i), int.parse(x) {
      True, Ok(v) -> Ok(DiskFile(id: i / 2, size: v))
      False, Ok(v) -> Ok(DiskFree(v))
      _, Error(_) ->
        Error(
          "Can't parse the value '" <> x <> "' at index " <> int.to_string(i),
        )
    }
  })
  |> result.all()
}

// Part 1

pub type Block {
  FileBlock(id: Int)
  FreeBlock
}

fn to_blocks(input: Puzzle) {
  input
  |> list.flat_map(fn(file) {
    case file {
      DiskFile(id, v) -> list.repeat(FileBlock(id), v)
      DiskFree(v) -> list.repeat(FreeBlock, v)
    }
  })
}

fn sort_blocks_loop(
  forwards: List(Block),
  backwards: List(Block),
  sorted: List(Block),
  taken: Int,
  total: Int,
) -> List(Block) {
  case forwards, backwards, taken >= total {
    // If we run out either way, then we're done!
    // Technically, we should only run out by hitting `total`, but
    // have to handle all cases
    _, _, True -> sorted
    [], _, _ -> sorted
    _, [], _ -> sorted

    // Otherwise...
    [FileBlock(x), ..rest], _, _ ->
      sort_blocks_loop(
        rest,
        backwards,
        [FileBlock(x), ..sorted],
        taken + 1,
        total,
      )
    [FreeBlock, ..rest], [FreeBlock, ..rest_back], _ ->
      sort_blocks_loop([FreeBlock, ..rest], rest_back, sorted, taken + 1, total)
    [FreeBlock, ..rest], [FileBlock(x), ..rest_back], _ ->
      sort_blocks_loop(
        rest,
        rest_back,
        [FileBlock(x), ..sorted],
        taken + 2,
        total,
      )
  }
}

fn sort_blocks(data: List(Block)) {
  sort_blocks_loop(data, list.reverse(data), [], 0, list.length(data))
  |> list.reverse()
}

fn checksum(data: List(Block)) -> Int {
  list.index_fold(data, from: 0, with: fn(total, block, ix) {
    case block {
      FileBlock(v) -> total + ix * v
      FreeBlock -> total
    }
  })
}

pub fn solve1(input: Puzzle) -> Result(Int, String) {
  input
  |> to_blocks()
  |> sort_blocks()
  |> checksum()
  |> Ok()
}

// Part 2

fn insert(id: Int, size: Int, into diskmap: DiskMap) {
  insert_loop(id, size, diskmap, []) |> list.reverse()
}

fn rm_file(from diskmap: DiskMap, at id: Int) {
  list.map(diskmap, fn(f) {
    case f {
      DiskFile(i, size) ->
        case i == id {
          True -> DiskFree(size)
          False -> f
        }
      DiskFree(_) -> f
    }
  })
}

fn insert_loop(id: Int, size: Int, to_search: DiskMap, searched: DiskMap) {
  case to_search {
    [] -> searched
    [DiskFree(available), ..rest] -> {
      case int.compare(size, available) {
        order.Eq ->
          list.append(list.reverse(rm_file(rest, id)), [
            DiskFile(id, size),
            ..searched
          ])
        order.Lt ->
          list.append(list.reverse(rm_file(rest, id)), [
            DiskFree(available - size),
            DiskFile(id, size),
            ..searched
          ])
        order.Gt ->
          insert_loop(id, size, rest, [DiskFree(available), ..searched])
      }
    }
    [DiskFile(f_id, f_size), ..rest] -> {
      case f_id == id {
        True -> list.append(list.reverse(to_search), searched)
        False ->
          insert_loop(id, size, rest, [DiskFile(f_id, f_size), ..searched])
      }
    }
  }
}

fn move_file_to_free_space(id: Int, size: Int, diskmap: DiskMap) {
  insert(id, size, into: diskmap)
}

pub fn solve2(input: Puzzle) -> Result(Int, String) {
  input
  |> list.reverse()
  |> list.fold(from: input, with: fn(diskmap, file) {
    case file {
      DiskFile(id, size) -> move_file_to_free_space(id, size, diskmap)
      DiskFree(_) -> diskmap
    }
  })
  |> to_blocks()
  |> checksum()
  |> Ok()
}

// Debugging :)

fn blocks_to_string(data: List(Block)) {
  list.map(data, fn(b) {
    case b {
      FileBlock(id) -> int.to_string(id)
      FreeBlock -> "."
    }
  })
  |> string.concat()
}
