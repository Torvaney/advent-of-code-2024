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
  // Kinda weird algorithm where we recurse over the list from the front and the
  // back simultaneously, building a new list (`sorted`) as we go...
  // We have to keep track of how many elements we've accounted for (`taken`)
  // to make sure we don't double-count anything...
  case forwards, backwards, taken >= total {
    // If we run out either way, then we're done!
    // Technically, we should only run out by hitting `total`, but
    // have to handle all cases
    _, _, True -> sorted
    [], _, _ -> sorted
    _, [], _ -> sorted

    // Otherwise...
    // If the next block is taken, increment counter and continue
    [FileBlock(x), ..rest], _, _ ->
      sort_blocks_loop(
        rest,
        backwards,
        [FileBlock(x), ..sorted],
        taken + 1,
        total,
      )

    // If next block is free *and* the last block is also free, increment counter
    // and throw away the last block
    // i.e. continue to the second-last block
    [FreeBlock, ..rest], [FreeBlock, ..rest_back], _ ->
      sort_blocks_loop([FreeBlock, ..rest], rest_back, sorted, taken + 1, total)

    // If the next block is free and the last block is part of a file, insert
    // data and continue
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

fn insert(id: Int, size: Int, into diskmap: DiskMap) -> List(DiskSpace) {
  insert_loop(id, size, diskmap, []) |> list.reverse()
}

fn insert_loop(
  id: Int,
  size: Int,
  to_search: DiskMap,
  searched: DiskMap,
) -> List(DiskSpace) {
  case to_search {
    // If there are no files left to search, we're done!
    [] -> searched

    // If the next space is free, see if it has enough space...
    // If it does, then insert the file and exit the loop (deleting file from its original location)
    [DiskFree(available), ..rest] -> {
      case int.compare(size, available) {
        order.Eq -> end_insert(id, rest, [DiskFile(id, size), ..searched])
        order.Lt ->
          end_insert(id, rest, [
            DiskFree(available - size),
            DiskFile(id, size),
            ..searched
          ])
        order.Gt ->
          insert_loop(id, size, rest, [DiskFree(available), ..searched])
      }
    }

    // If the next space isn't free, just continue to the next space...
    [DiskFile(f_id, f_size), ..rest] -> {
      case f_id == id {
        True -> list.append(list.reverse(to_search), searched)
        False ->
          insert_loop(id, size, rest, [DiskFile(f_id, f_size), ..searched])
      }
    }
  }
}

fn end_insert(
  insert_id: Int,
  unsearched: List(DiskSpace),
  searched: List(DiskSpace),
) -> List(DiskSpace) {
  list.append(list.reverse(rm_file(unsearched, insert_id)), searched)
}

fn rm_file(from diskmap: DiskMap, at id: Int) -> List(DiskSpace) {
  // When we insert the file somewhere, we need to remove it from the its original
  // location on the disk
  list.map(diskmap, fn(f) {
    case f {
      DiskFile(i, size) if i == id -> DiskFree(size)
      _ -> f
    }
  })
}

fn move_file_to_free_space(id: Int, size: Int, diskmap: DiskMap) {
  insert(id, size, into: diskmap)
}

pub fn solve2(input: Puzzle) -> Result(Int, String) {
  input
  |> list.reverse()
  // Fold over the files backwards (i.e. from the "right"),
  // inserting into leftmost free space for each one
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
