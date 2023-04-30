type vec3 = Types.vec3

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

type modifier = {
    operation: int,
    amount: float
}

type attribute = {
    value: float,
    modifiers: array<modifier>
}

type attributes = {
    "minecraft:generic.movement_speed": option<attribute>
}

type effect = {
    amplifier: int,
    duration: int
}

type effects = {
    "8": option<effect>
}

type entity = {
    attributes: option<attributes>,
    effects: effects
}

type modifiers = {
    movement: float,
    jump: float
}

let inject = (bot: Types.client) => {
    let chunk = Chunk.inject(bot)
    let block = Block.inject(bot)
    
    // the slip block is exactly 1 block down from the player's actual position
    let getSlip = (position: vec3) => {
        let state = position -> chunk.getBlock -> Utils.unwrapInt
        switch (state -> block.getName -> Utils.unwrapStr) {
            | "slime_block" => 0.8
            | "ice" => 0.98
            | "packed_ice" => 0.98
            | "blue_ice" => 0.989
            | _ => 0.6 // everything else
        }
    }

    let getModifiers = (entity: entity) => {
        movement: switch (entity.attributes) {
            | Some(attributes) => switch (attributes["minecraft:generic.movement_speed"]) {
                | Some(attribute) => {
                    let weight = ref(attribute.value)
                    // append speed attribute modifiers to final weight
                    for i in 0 to Array.length(attribute.modifiers) - 1 {
                        let modifier = attribute.modifiers[i]
                        weight := switch (modifier.operation) {
                            | 0 => weight.contents +. modifier.amount
                            | 1 => weight.contents +. attribute.value *. (1.0 +. modifier.amount)
                            | 2 => weight.contents +. attribute.value *. modifier.amount
                            | _ => weight.contents
                        }
                    }
                    weight.contents *. 10.0
                }
                // no movement speed attribute
                | None => 1.0
            }
            // no attributes at all
            | None => 1.0
        },
        jump: switch (entity.effects["8"]) {
            | Some(effect) => effect.amplifier -> Belt.Int.toFloat *. 0.1
            | None => 0.0
        }
    }

}