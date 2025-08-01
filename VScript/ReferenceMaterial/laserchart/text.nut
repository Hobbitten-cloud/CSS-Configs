class Text {
    entity = null

    constructor(x, y, color, channel, all_players, text) {
        local spawnflags = 0

        if (all_players) {
            spawnflags = 1
        }

        this.entity = SpawnEntityFromTable("game_text", {
            Message = text,
            X = x.tostring(),
            Y = y.tostring(),
            Channel = channel,
            Color = color,
            Effect = "0",
            FadeIn = "0.25",
            FadeOut = "0.5",
            HoldTime = "2",
            spawnflags = spawnflags
        })
    }

    function setText(text) {
        this.entity.__KeyValueFromString("message", text)
    }

    function display(player = null) {
        EntFireByHandle(this.entity, "Display", null, 0, player, null)
    }

    function kill() {
        this.entity.Kill()
    }
}

module <- Text