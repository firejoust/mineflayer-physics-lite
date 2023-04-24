type client = {}

type vec3 = {
    x: float,
    y: float,
    z: float
}

type block = {
    position: vec3,
    stateId: int,
    shapes: array<array<float>>
}

type column = {
    getBlock: (float, float, float) => block,
    sections: array<unknown>,
    minY: int
}