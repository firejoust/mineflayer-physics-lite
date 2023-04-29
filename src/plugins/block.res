type shapes = array<array<float>>

type blockData = {
    name: string,
    stateId: int,
    shapes: shapes,
    minStateId: option<int>,
    maxStateId: option<int>,
    stateShapes: option<array<shapes>>
}

type plugin = {
    getShape: int => option<shapes>,
    getName: int => option<string>
}

@warning("-27")
let inject = (bot: Types.client) => {
    let blocks: array<blockData> = %raw(`bot.registry.blocksArray`)
    let blockShapes = Belt.HashMap.Int.make(~hintSize=0xfff)
    let blockNames = Belt.HashMap.Int.make(~hintSize=0xfff)

    for i in 0 to Array.length(blocks) - 1 {
        let block = blocks[i]
        switch (block.minStateId, block.maxStateId) {
            // multiple variants of the same block
            | (Some(min), Some(max)) => switch (block.stateShapes) {
                | Some(stateShapes) => {
                    for j in min to max {
                        Belt.HashMap.Int.set(blockShapes, j, stateShapes[j - min])
                        Belt.HashMap.Int.set(blockNames, j, block.name)
                    }
                }
                // no unique shapes for the block variants
                | _ => {
                    for j in min to max {
                        Belt.HashMap.Int.set(blockShapes, j, block.shapes)
                        Belt.HashMap.Int.set(blockNames, j, block.name)
                    }
                }
            }
            // only a single variant of that block
            | _ => {
                Belt.HashMap.Int.set(blockShapes, block.stateId, block.shapes)
                Belt.HashMap.Int.set(blockNames, block.stateId, block.name)
            }
        }
    }

    let getShape = stateId => Belt.HashMap.Int.get(blockShapes, stateId)
    let getName = stateId => Belt.HashMap.Int.get(blockNames, stateId)

    {
        getShape: getShape,
        getName: getName
    }
}