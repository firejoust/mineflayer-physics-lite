
@warning("-21")
let inject = (bot: Types.client) => {
    let chunkMap = Belt_Map.make(~id=module(Utils.StringCmp))

    {
        let on = %raw(`
            (label, callback) => {
                bot.on(label, callback)
            }
        `)

        let getColumn = %raw(`
            async (x, z) => {
                return bot.world.async.getColumn(x, z)
            }
        `)

        let getBlock = %raw(`
            (column, x, y, z) => {
                return column.getBlockStateId({x, y, z})
            }
        `)

        let loadColumn = async (x: int, z: int) => {
            let x0 = x * 0x10
            let z0 = z * 0x10

            let column: Types.column = await getColumn(x, z)
            let size = Array.length(column.sections)

            let sections = Array.init(size, _ => Array.make(4096, 0))
            let y0 = column.minY

            for i in 0 to size - 1 {
                let j = ref(0)
                let y1 = i * 0x10

                Utils.xyzIterator(0xf, (x, y, z) => {
                    let stateId = getBlock(column, x0 + x, y0 + y1 + y, z0 + z)
                    Array.set(sections[i], j.contents, stateId)
                    j :=+ 1
                })
            }

            Js.log(sections)
        }

        let unloadColumn = (x: int, z: int) => {
            ()
        }

        on("chunkColumnLoad", async (position: Types.vec3) => {
            loadColumn(Belt.Float.toInt(position.x) / 0x10, Belt.Float.toInt(position.z) / 0x10)
        })

        on("chunkColumnUnload", async (position: Types.vec3) => {
            unloadColumn(Belt.Float.toInt(position.x) / 0x10, Belt.Float.toInt(position.z) / 0x10)
        })
    }
}