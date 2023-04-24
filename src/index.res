let plugin = async (bot: Types.client) => {
    let chunk = Chunk.inject(bot)
    let _ = chunk.getBlock(0, 0, 0)
    %raw(`bot.getBlock = chunk.getBlock`)
}