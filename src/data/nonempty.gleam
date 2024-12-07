import gleam/list

pub opaque type NonEmpty(a) {
  NonEmpty(head: a, body: List(a))
}

// Construction

pub fn from_list(xs: List(a)) -> Result(NonEmpty(a), Nil) {
  case xs {
    [first, ..rest] -> Ok(NonEmpty(head: first, body: rest))
    [] -> Error(Nil)
  }
}

pub fn to_list(nonempty: NonEmpty(a)) -> List(a) {
  [nonempty.head, ..nonempty.body]
}

// Getting values

pub fn head(nonempty: NonEmpty(a)) -> a {
  nonempty.head
}

pub fn body(nonempty: NonEmpty(a)) -> List(a) {
  nonempty.body
}

// Getting other info

pub fn length(nonempty: NonEmpty(a)) -> Int {
  list.length(nonempty.body) + 1
}
