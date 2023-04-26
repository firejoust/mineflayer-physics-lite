Js.log(Belt.Int.toString((-16 -9) / 0x10))

let plugin = async (bot: Types.client) => {
    let chunk = Chunk.inject(bot)
    let _ = chunk.getBlock(0.0, 0.0, 0.0)
    %raw(`bot.getBlock = chunk.getBlock`)
}