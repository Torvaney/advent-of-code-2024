import gleam/result

pub fn try_with_msg(
  result: Result(a, Nil),
  msg: String,
  apply fun: fn(a) -> Result(b, String),
) -> Result(b, String) {
  result.try(result |> result.replace_error(msg), apply: fun)
}
