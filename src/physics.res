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

type plugin = {
    getSlip: vec3 => float,
    getEffects: entity => effects,
    getMovement: controls => float,
    getNextState: (entityState, controls, effects) => unit
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

    let getEffects = (entity: entity): effects => {
        speed: switch (entity.effects["1"]) {
            | Some(effect) => effect.amplifier
            | None => 0
        },
        slowness: switch (entity.effects["2"]) {
            | Some(effect) => effect.amplifier
            | None => 0
        },
        jump_boost: switch (entity.effects["8"]) {
            | Some(effect) => effect.amplifier
            | None => 0
        }
    }

    let getMovement = (controls: controls): float => {
        let multiplier = (
            if controls.sprint {
                1.3
            } else

            if controls.sneak {
                0.3
            } else

            if controls.forward || controls.back || controls.left || controls.right {
                1.0
            } else 
            
            {
                0.0
            }
        )

        // 45 degrees strafe
        if Utils.xor(controls.forward, controls.back) && Utils.xor(controls.left, controls.right) {
            if (controls.sneak) {
                multiplier *. 0.98 *. Js.Math._SQRT2
            } else {
                multiplier
            }
        } else {
            multiplier *. 0.98
        }
    }

    let getNextState = (state, controls, effects) => {
        let em = (1.0 +. 0.2 *. Belt.Int.toFloat(effects.speed)) +. (1.0 -. 0.15 *. Belt.Int.toFloat(effects.slowness))
        let sm = Utils.offsetVec(state.position, 0.0, -1.0, 0.0) -> getSlip
        let mm = getMovement(controls)


    }

    {
        getSlip,
        getEffects,
        getMovement,
        getNextState
    }
}