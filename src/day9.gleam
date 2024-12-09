import data/amphista
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/pair
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

pub fn solve2(input: Puzzle) -> Result(Int, String) {
  Error("Part 2 not implemented yet!")
}
