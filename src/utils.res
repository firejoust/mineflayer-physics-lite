let xyzIterator = (radius, callback) => {
    for x in 0 to radius {
        for y in 0 to radius {
            for z in 0 to radius {
                callback(x, y, z)
            }
        }
    }
}

module IntCmp = Belt.Id.MakeComparable({
  type t = int
  let cmp = (a, b) => Pervasives.compare(a, b)
})

module StringCmp = Belt.Id.MakeComparable({
  type t = string
  let cmp = (a, b) => Pervasives.compare(a, b)
})