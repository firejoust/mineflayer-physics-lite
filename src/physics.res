open Types

type plugin = {
    getEffects: entity => effects,
    getNextState: (entityState, controls, effects) => float
}

/*
    CONSTANTS
*/

let radian180 = Js.Math._PI
let radian90  = Js.Math._PI /. 2.0
let radian45  = Js.Math._PI /. 4.0

let slipOffset = -0.6 // 1.15+ is 0.6, 1.14.4 and lower is 1.0
let stepOffset = 0.6
let negligibleY = 0.003
let playerHeight = 1.8

/*
    METHODS
*/

let getBoundingBox = (state) => {
    a: {
        x: state.position.x -. 0.3,
        y: state.position.y,
        z: state.position.z -. 0.3
    },
    b: {
        x: state.position.x +. 0.3,
        y: state.position.y +. playerHeight,
        z: state.position.z +. 0.3
    }
}

let getEffects = (entity) => {
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

let getEffectMultiplier = (effects) => {
    (1.0 +. 0.2 *. Belt.Int.toFloat(effects.speed)) +. (1.0 -. 0.15 *. Belt.Int.toFloat(effects.slowness))
}

let getMovement = (controls): float => {
    let multiplier = (
        if controls.sneak {
            0.3
        } else

        if controls.sprint {
            1.3
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

let getDirection = (yaw, controls) => {
    let forward = Utils.xor(controls.forward, controls.back)
    let sideward = Utils.xor(controls.right, controls.left)

    switch (forward, sideward) {
        // multiple strafe keys at once
        | (true, true) => if controls.forward {
            if controls.left {
                yaw +. radian45
            } else {
                yaw -. radian45
            }
        } else {
            if controls.left {
                yaw +. radian180 -. radian45
            } else {
                yaw -. radian180 +. radian45
            }
        }

        // only forward/backward strafe keys
        | (true, false) => if controls.forward {
            yaw
        } else {
            yaw +. radian180
        }

        // only left/right strafe keys
        | (false, true) => if controls.left {
            yaw +. radian90
        } else {
            yaw -. radian90
        }
        
        // no strafe keys or conflicting strafe keys
        | (false, false) => yaw
    }
}

/*
    PLUGIN
*/

let inject = (bot) => {
    let chunk = Chunk.inject(bot)
    let block = Block.inject(bot)
    
    let getSlip = (state) => if state.onGround {
        let state = state.position
        -> Utils.offsetVec(0.0, slipOffset, 0.0)
        -> chunk.getBlock
        -> Utils.unwrapInt

        switch (state -> block.getName -> Utils.unwrapStr) {
            | "slime_block" => 0.8
            | "ice" => 0.98
            | "packed_ice" => 0.98
            | "blue_ice" => 0.989
            | _ => 0.6 // everything else
        }
    } else {
        1.0
    }

    // 1. acceleration + jump boost is added to velocity in existing state, making new velocity.
    // 2. the new velocity is added onto the existing state position, making new position.
    // 3. the new velocity is set to the momentum component, simulating drag.
    // 4. the new state is returned with that new position and the new velocity (including the drag)

    let getNextState = (state, controls, effects) => {
        let effects = getEffectMultiplier(effects)
        let movement = getMovement(controls)
        let slip = getSlip(state)
        let direction = state.yaw -> getDirection(controls)

        let (ax, ay, az) = if state.onGround && controls.jump {(
            (0.1 *. movement *. effects *. (0.6 /. slip) ** 3.0 *. -.Js.Math.sin(direction)) +. (0.2 *. -.Js.Math.sin(state.yaw)),
            0.42,
            (0.1 *. movement *. effects *. (0.6 /. slip) ** 3.0 *. -.Js.Math.cos(direction)) +. (0.2 *. -.Js.Math.cos(state.yaw))
        )} else

        if state.onGround {(
            0.1 *. movement *. effects *. (0.6 /. slip) ** 3.0 *. -.Js.Math.sin(direction),
            0.0,
            0.1 *. movement *. effects *. (0.6 /. slip) ** 3.0 *. -.Js.Math.cos(direction)
        )} else

        {(
            0.02 *. movement *. -.Js.Math.sin(direction),
            0.0,
            0.02 *. movement *. -.Js.Math.cos(direction)
        )}

        let vx = state.velocity.x +. ax
        let vy = state.velocity.y +. ay // keep track of y
        let vz = state.velocity.z +. az

        let px = state.position.x +. vx
        let py = state.position.y +. vy
        let pz = state.position.z +. vz

        let vx = vx *. slip *. 0.91
        let vy = vy < negligibleY ? (vy -. 0.08) *. 0.98 : 0.0
        let vz = vz *. slip *. 0.91 

        vx +. vy +. vz
    }

    {
        getEffects,
        getNextState
    }
}