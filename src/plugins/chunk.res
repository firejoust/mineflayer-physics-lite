open Types

type plugin = {
    getBlock: vec3 => option<int>
}

@warning("-21")
@warning("-27")
let inject = (bot) => {
    // todo: set to chunk render distance
    let chunkMap = Belt.HashMap.String.make(~hintSize=0xff)
    let chunkMapHeight = Belt.HashMap.String.make(~hintSize=0xff)

    let on = %raw(`
        (label, callback) => {
            bot.on(label, callback)
        }
    `)

    let getColumnJs: (int, int) => column = %raw(`
        (x, z) => bot.world.async.getLoadedColumn(x, z)
    `)

    let getBlockJs: (column, int, int, int) => int = %raw(`
        (column, x, y, z) => column.getBlockStateId({x, y, z})
    `)

    let loadColumn = (x, z) => {
        let column: column = getColumnJs(x, z)
        let size = Array.length(column.sections)
        let sections = Array.init(size, _ => Array.make(4096, 0))

        for i in 0 to size - 1 {
            let j = ref(0)
            let y0 = i * 0x10

            Utils.xyzIterator(0xf, (x, y, z) => {
                let stateId = getBlockJs(column, x, y0 + y + column.minY, z) // pos in chunk
                Array.set(sections[i], j.contents, stateId)
                j := j.contents + 1
            })
        }

        let key = Belt.Int.toString(x) ++ "," ++ Belt.Int.toString(z)
        Belt.HashMap.String.set(chunkMap, key, sections)
        Belt.HashMap.String.set(chunkMapHeight, key, column.minY)
    }

    let unloadColumn = (x, z) => {
        let key = Belt.Int.toString(x) ++ "," ++ Belt.Int.toString(z)
        Belt.HashMap.String.remove(chunkMap, key)
    }

    let updateBlock = (_, block: block) => {
        let x = Js.Math.floor_int(block.position.x)
        let y = Js.Math.floor_int(block.position.y)
        let z = Js.Math.floor_int(block.position.z)

        let key = Belt.Int.toString(Utils.floorDivInt(x, 0x10)) ++ "," ++ Belt.Int.toString(Utils.floorDivInt(z, 0x10))
        let sections = Belt.HashMap.String.get(chunkMap, key)
        let minY = Belt.HashMap.String.get(chunkMapHeight, key)

        switch (sections, minY) {
            | (Some(sections), Some(minY)) => {
                let index = Utils.floorDivInt(y - minY, 0x10)
                if index > -1 && index < Array.length(sections) {
                    let x0 = x - Utils.floorDivInt(x, 0x10) * 0x10
                    let y0 = y - Utils.floorDivInt(y, 0x10) * 0x10
                    let z0 = z - Utils.floorDivInt(z, 0x10) * 0x10

                    sections[index][
                        z0
                        + y0 * 0x10
                        + x0 * 0x100
                    ] = block.stateId
                }
            }
            | _ => ()
        }
    }

    on("chunkColumnLoad", async (position) => {
        loadColumn(Utils.floorDiv(position.x, 16.0), Utils.floorDiv(position.z, 16.0))
    })

    on("chunkColumnUnload", async (position) => {
        unloadColumn(Utils.floorDiv(position.x, 16.0), Utils.floorDiv(position.z, 16.0))
    })

    on("blockUpdate", async (a, b) => {
        updateBlock(a, b)
    })

    let getBlock = (position) => {
        let key = Utils.floorDiv(position.x, 16.0) -> Belt.Int.toString
            ++ ","
            ++ Utils.floorDiv(position.z, 16.0) -> Belt.Int.toString
        
        // floor position
        let x = Js.Math.floor_int(position.x)
        let y = Js.Math.floor_int(position.y)
        let z = Js.Math.floor_int(position.z)

        let sections = Belt.HashMap.String.get(chunkMap, key)
        let minY = Belt.HashMap.String.get(chunkMapHeight, key)

        switch (sections, minY) {
            | (Some(sections), Some(minY)) => {
                let index = Utils.floorDivInt(y - minY, 0x10)

                // not within y range
                if index <= -1 || index >= Array.length(sections) {
                    None
                } else {
                    let chunkX = Utils.floorDivInt(x, 0x10) * 0x10
                    let chunkY = Utils.floorDivInt(y, 0x10) * 0x10
                    let chunkZ = Utils.floorDivInt(z, 0x10) * 0x10

                    let x0 = x - chunkX
                    let y0 = y - chunkY
                    let z0 = z - chunkZ

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