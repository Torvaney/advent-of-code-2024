import gleam/list
import gleam/string

pub fn parse_by_line(input: String, with parse_row: fn(String) -> Result(a, err)) -> Result(List(a), err) {
    string.split(input, "\n")
    |> list.filter(fn(x) { !string.is_empty(x) })
    |> list.try_map(parse_row)
}
