import gleam/list
import gleam/pair
import gleam/set

type Edge(a) {
  Edge(from: a, to: a)
}

pub opaque type DirectedGraph(a) {
  DirectedGraph(nodes: set.Set(a), edges: set.Set(Edge(a)))
}

// Constructing a DAG

pub fn new(from edges: set.Set(#(a, a))) -> DirectedGraph(a) {
  DirectedGraph(
    nodes: nodes_from_edges(edges),
    edges: set.map(edges, pair_to_edge),
  )
}

fn pair_to_edge(pair: #(a, a)) {
  Edge(pair.0, pair.1)
}

fn nodes_from_edges(edges: set.Set(#(a, a))) {
  set.union(set.map(edges, pair.first), set.map(edges, pair.second))
}

// Graph operations

pub fn is_valid_path(in graph: DirectedGraph(a), using path: List(a)) {
  list.window_by_2(path)
  |> list.all(fn(pair) {
    set.contains(in: graph.edges, this: pair_to_edge(pair))
  })
}
