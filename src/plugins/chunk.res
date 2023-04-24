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
            return column.getBlockStateId({x, y, z})
        }
    `)

    let loadColumn = async (x: int, z: int) => {
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
                j :=+ 1
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

    on("chunkColumnLoad", async (position: Types.vec3) => {
        loadColumn(Belt.Float.toInt(position.x) / 0x10, Belt.Float.toInt(position.z) / 0x10)
    })

    on("chunkColumnUnload", async (position: Types.vec3) => {
        unloadColumn(Belt.Float.toInt(position.x) / 0x10, Belt.Float.toInt(position.z) / 0x10)
    })

    let getBlock = (x, y, z) => {
        let key = Belt.Int.toString(x / 0x10) ++ "," ++ Belt.Int.toString(z / 0x10)
        let sections = Belt.HashMap.String.get(chunkMap, key)
        let minY = Belt.HashMap.String.get(chunkMapHeight, key)

        switch (sections, minY) {
            | (Some(sections), Some(minY)) => {
                let index = ((y - minY) / 0x10)
                // not within y range
                if -1 <= index || index >= Array.length(sections) {
                    None
                } else {
                    let x0 = x - ((x / 0x10) * 0x10)
                    let y0 = (y - minY) - (((y - minY) / 0x10) * 0x10) 
                    let z0 = z - ((z / 0x10) * 0x10)
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