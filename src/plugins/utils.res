let xyzIterator = (radius, callback) => {
    for x in 0 to radius {
        for y in 0 to radius {
            for z in 0 to radius {
                callback(x, y, z)
            }
        }
    }
}

let compareInt = (a: int, b: int) => Pervasives.compare(a, b)