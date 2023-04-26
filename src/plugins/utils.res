let xyzIterator = (radius, callback) => {
    for x in 0 to radius {
        for y in 0 to radius {
            for z in 0 to radius {
                callback(x, y, z)
            }
        }
    }
}

let floorDiv = (a: float, b: float) => {
    Js.Math.floor_int(a /. b)
}

let floorDivInt: (int, int) => int = %raw(`
    (a, b) => Math.floor(a / b) | 0
`)

let compareInt = (a: int, b: int) => Pervasives.compare(a, b)