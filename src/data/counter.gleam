import gleam/dict
import gleam/int
import gleam/list
import gleam/option
import gleam/pair

pub opaque type Counter(a) {
  Counter(data: dict.Dict(a, Int))
}

pub fn new() {
  Counter(dict.new())
}

pub fn from_list(items: List(a)) -> Counter(a) {
  update(new(), items)
}

pub fn update(counter: Counter(a), items: List(a)) -> Counter(a) {
  list.fold(items, counter, fn(c, x) { insert(c, x) })
}

pub fn update_by(counter: Counter(a), items: List(a), by n: Int) -> Counter(a) {
  list.fold(items, counter, fn(c, x) { increment(c, x, by: n) })
}

pub fn insert(counter: Counter(a), item: a) {
  increment(counter, item, 1)
}

pub fn increment(counter: Counter(a), item: a, by n: Int) {
  Counter(
    dict.upsert(counter.data, item, fn(x) {
      x |> option.unwrap(0) |> int.add(n)
    }),
  )
}

pub fn decrement(counter: Counter(a), item: a, by n: Int) -> Counter(a) {
  case dict.get(counter.data, item) {
    Ok(i) if i > n -> Counter(dict.insert(counter.data, item, i - n))
    _ -> Counter(dict.delete(counter.data, item))
  }
}

pub fn total(counter: Counter(a)) {
  to_list(counter) |> list.map(pair.second) |> int.sum()
}

pub fn to_list(counter: Counter(a)) -> List(#(a, Int)) {
  dict.to_list(counter.data)
}
