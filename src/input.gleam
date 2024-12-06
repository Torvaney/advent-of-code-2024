import gleam/list
import gleam/result
import gleam/string

pub fn parse_by_line(
  input: String,
  with parse_row: fn(String) -> Result(a, err),
) -> Result(List(a), err) {
  string.split(input, "\n")
  |> list.filter(fn(x) { !string.is_empty(x) })
  |> list.try_map(parse_row)
}

pub fn parse_pair(
  input: String,
  split_on substring: String,
  with parse_unit: fn(String) -> Result(a, err),
) -> Result(#(a, a), String) {
  use items <- try_with_msg(
    string.split_once(input, substring),
    "Failed to split row: '" <> input <> "' on '" <> substring <> "'",
  )

  let #(s1, s2) = items

  use parsed1 <- try_with_msg(parse_unit(s1), "Failed to parse: '" <> s1 <> "'")
  use parsed2 <- try_with_msg(parse_unit(s2), "Failed to parse: '" <> s2 <> "'")

  Ok(#(parsed1, parsed2))
}

pub fn parse_list(
  input: String,
  with parse_unit: fn(String) -> Result(a, err),
) -> Result(List(a), err) {
  string.split(input, ",")
  |> list.try_map(parse_unit)
}

// Utils

pub fn try_with_msg(
  result: Result(a, err),
  msg: String,
  apply fun: fn(a) -> Result(b, String),
) -> Result(b, String) {
  result.try(result |> result.replace_error(msg), apply: fun)
}
