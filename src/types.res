type block = {
    stateId: int,
    shapes: array<array<float>>
}

type column = {
    getBlock: (float, float, float) => block,
    sections: array<unknown>,
    minY: int
}

module World = {
    type world = {
        getColumn: (int, int) => column
    }
}

type registry = {

}

type client = {
    world: World.world,
    registry: registry
}

type vec3 = {
    x: float,
    y: float,
    z: float
}