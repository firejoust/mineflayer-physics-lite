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
        async (x, z) => {
            return bot.world.async.getColumn(x, z)
        }
    `)

    let getBlockJs = %raw(`
        (column, x, y, z) => {
            if (
                Math.sqrt((x - bot.entity.position.x) ** 2 + (y - bot.entity.position.y) ** 2 + (z - bot.entity.position.z) ** 2) <= 1.5
            ) {
                console.log("at "+x+","+y+","+z+": "+column.getBlockStateId({x, y, z}))
            }
            
            return column.getBlockStateId({x, y, z})
        }
    `)

    let loadColumn = async (x, z) => {
        let x0 = x * 0x10
        let z0 = z * 0x10

        let column: Types.column = await getColumnJs(x, z)
        let size = Array.length(column.sections)

        let sections = Array.init(size, _ => Array.make(4096, 0))
        let y0 = column.minY

        for i in 0 to size - 1 {
            let j = ref(0)
            let y1 = i * 0x10

            Utils.xyzIterator(0xf, (x, y, z) => {
                let stateId = getBlockJs(column, x0 + x, y0 + y1 + y, z0 + z)
                Array.set(sections[i], j.contents, stateId)
                j := j.contents + 1
            })
        }

        let key = Belt.Int.toString(x) ++ "," ++ Belt.Int.toString(z)
        Belt.HashMap.String.set(chunkMap, key, sections)
        Belt.HashMap.String.set(chunkMapHeight, key, y0)
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
                    let x0 = x - ((x / 0x10) * 0x10)
                    let y0 = (y - minY) - (index * 0x10)
                    let z0 = z - ((z / 0x10) * 0x10)

                    let x0 = x0 < 0
                    ? 0x10 + x0
                    : x0

                    let y0 = y0 < 0
                    ? 0x10 + y0
                    : y0

                    let z0 = z0 < 0
                    ? 0x10 + z0
                    : z0

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
                    let x0 = x - ((x / 0x10) * 0x10)
                    let y0 = (y - minY) - (index * 0x10)
                    let z0 = z - ((z / 0x10) * 0x10)

                    let x0 = x0 < 0
                    ? 0x10 + x0
                    : x0

                    let y0 = y0 < 0
                    ? 0x10 + y0
                    : y0

                    let z0 = z0 < 0
                    ? 0x10 + z0
                    : z0
                    
                    Js.log(`x0 to x:`)
                    Js.log((z / 0x10) * 0x10)
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