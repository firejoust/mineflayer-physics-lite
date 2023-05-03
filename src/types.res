type client = {}

type vec3 = {
    mutable x: float,
    mutable y: float,
    mutable z: float
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

type box = {
    a: vec3,
    b: vec3
}

type entityState = {
    yaw: float,
    position: vec3,
    velocity: vec3,
    onGround: bool,
    isInWater: bool,
    isInLava: bool,
    isInWeb: bool,
    isCollidedHorizontally: bool,
    isCollidedVertically: bool,
}

type entityEffect = {
    amplifier: int,
    duration: int
}

type entityEffects = {
    "1": option<entityEffect>, // speed
    "2": option<entityEffect>, // slowness
    "8": option<entityEffect>  // jump
}

type entity = {
    effects: entityEffects
}

type controls = {
    forward: bool,
    back: bool,
    left: bool,
    right: bool,
    jump: bool,
    sneak: bool,
    sprint: bool,
}

type effects = {
    speed: int,
    slowness: int,
    jump_boost: int
}

type shapes = array<array<float>>

type blockData = {
    name: string,
    stateId: int,
    shapes: shapes,
    minStateId: option<int>,
    maxStateId: option<int>,
    stateShapes: option<array<shapes>>
}