type plugin = {
    getBlock: (int, int, int) => option<int>
}

@warning("-21")
@warning("-27")
let inject = (bot: Types.client) => {
    // todo: set to chunk render distance
    let chunkMap = Belt.HashMap.String.make(~hintSize=0xff)
    let chunkMapHeight = Belt.HashMap.String.make(~hintSize=0xff)

    let on = %raw(`
        (label, callback) => {
            bot.on(label, callback)
        }
    `)

    let getColumnJs = %raw(`
        (x, z) => {
            return bot.world.async.getLoadedColumn(x, z)
        }
    `)

    let getBlockJs = %raw(`
        (column, x, y, z) => {
            /*
                IMPORTANT!!!

                We cannot use the raw x,y,z for this function!
                We need to convert it to the chunk pos first:

                function posInChunk (pos) {
                    return new Vec3(Math.floor(pos.x) & 15, Math.floor(pos.y), Math.floor(pos.z) & 15)
                }
            */
            return column.getBlockStateId({x, y, z})
        }
    `)

    let loadColumn = (x, z) => {
        let column: Types.column = getColumnJs(x, z)
        let size = Array.length(column.sections)
        let sections = Array.init(size, _ => Array.make(4096, 0))

        for i in 0 to size - 1 {
            let j = ref(0)
            let y0 = i * 0x10

            Utils.xyzIterator(0xf, (x, y, z) => {
                let stateId = getBlockJs(column, x, y + y0 + column.minY, z) // pos in chunk
                Array.set(sections[i], j.contents, stateId)
                j := j.contents + 1
            })
        }

        let key = Belt.Int.toString(x) ++ "," ++ Belt.Int.toString(z)
        Belt.HashMap.String.set(chunkMap, key, sections)
        Belt.HashMap.String.set(chunkMapHeight, key, column.minY)
    }

    let unloadColumn = (x: int, z: int) => {
        let key = Belt.Int.toString(x) ++ "," ++ Belt.Int.toString(z)
        Belt.HashMap.String.remove(chunkMap, key)
    }

    let updateBlock = (_, b: Types.block) => {
        let x = Belt.Int.fromFloat(b.position.x)
        let y = Belt.Int.fromFloat(b.position.y)
        let z = Belt.Int.fromFloat(b.position.z)

        Js.log4("block changed at", x, y, z)

        let key = Belt.Int.toString(x / 0x10) ++ "," ++ Belt.Int.toString(z / 0x10)
        let sections = Belt.HashMap.String.get(chunkMap, key)
        let minY = Belt.HashMap.String.get(chunkMapHeight, key)

        switch (sections, minY) {
            | (Some(sections), Some(minY)) => {
                let index = (y - minY) / 0x10
                if index > -1 && index < Array.length(sections) {
                    let chunkX = x < 0
                    ? (x / 0x10) * 0x10 - 0xf
                    : (x / 0x10) * 0x10

                    let chunkY = y < 0
                    ? (y / 0x10) * 0x10 - 0xf
                    : (y / 0x10) * 0x10

                    let chunkZ = z < 0
                    ? (z / 0x10) * 0x10 - 0xf
                    : (z / 0x10) * 0x10

                    let x0 = x - chunkX
                    let y0 = y - chunkY
                    let z0 = z - chunkZ

                    sections[index][
                        z0
                        + y0 * 0x10
                        + x0 * 0x100
                    ] = b.stateId
                }
            }
            | _ => ()
        }
    }

    on("chunkColumnLoad", async (position: Types.vec3) => {
        loadColumn(Belt.Float.toInt(position.x) / 0x10, Belt.Float.toInt(position.z) / 0x10)
    })

    on("chunkColumnUnload", async (position: Types.vec3) => {
        unloadColumn(Belt.Float.toInt(position.x) / 0x10, Belt.Float.toInt(position.z) / 0x10)
    })

    on("blockUpdate", async (a: Types.block, b: Types.block) => {
        updateBlock(a, b)
    })

    let getBlock = (x, y, z) => {
        let key = Belt.Int.toString(x / 0x10) ++ "," ++ Belt.Int.toString(z / 0x10)
        let sections = Belt.HashMap.String.get(chunkMap, key)
        let minY = Belt.HashMap.String.get(chunkMapHeight, key)

        switch (sections, minY) {
            | (Some(sections), Some(minY)) => {
                let index = ((y - minY) / 0x10)
                // not within y range
                if index <= -1 || index >= Array.length(sections) {
                    None
                } else {
                    let chunkX = x < 0
                    ? (x / 0x10) * 0x10 - 0xf
                    : (x / 0x10) * 0x10

                    let chunkY = y < 0
                    ? (y / 0x10) * 0x10 - 0xf
                    : (y / 0x10) * 0x10

                    let chunkZ = z < 0
                    ? (z / 0x10) * 0x10 - 0xf
                    : (z / 0x10) * 0x10

                    Js.log(`chunkX: ${Belt.Int.toString(chunkX)}`)
                    Js.log(`chunkY: ${Belt.Int.toString(chunkY)}`)
                    Js.log(`chunkZ: ${Belt.Int.toString(chunkZ)}`)

                    let x0 = x - chunkX
                    let y0 = y - chunkY
                    let z0 = z - chunkZ

                    Js.log3(x0, y0, z0)

                    // get block in same order that it was placed into array
                    Some(sections[index][
                        z0
                        + y0 * 0x10
                        + x0 * 0x100
                    ])
                }
            }

            // not within x or z range
            | _ => None
        }
    }

    {
        getBlock: getBlock
    }
}