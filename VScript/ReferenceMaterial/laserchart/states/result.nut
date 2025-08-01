local Sprite = require("sprite")

class Result {
    game = null
    teleport = null
    entities = null

    constructor(game) {
        this.game = game
        this.teleport = Entities.FindByName(null, "result_teleport")
        this.entities = []
    }

    function showScores() {
        local timescale = Convars.GetFloat("host_timescale")
        local cheats = Convars.GetInt("sv_cheats")

        local lc_player = this.game.laserChartPlayer

        local scores = lc_player.playerScores

        foreach (score in scores) {
            local player = score.player
            player.SetOrigin(this.teleport.GetOrigin() + Vector(0, 0, 8))
            player.SnapEyeAngles(this.teleport.EyeAngles())
        }

        local chart_name_label = Entities.FindByName(null, "chart_name_label")
        local author_label = Entities.FindByName(null, "author_label")
        local hits_label = Entities.FindByName(null, "hits_label")
        local mods_label = Entities.FindByName(null, "mods_label")
        local chart_bg = Entities.FindByName(null, "chart_bg")

        local laser_chart = lc_player.laserChart
        EntFireByHandle(chart_name_label, "SetText", format("%s - %s", laser_chart.artist, laser_chart.title), 0, null, null)
        EntFireByHandle(author_label, "SetText", format("Original author: %s (From osu!mania/Etterna)\nThis chart is converted from 4k/7k VSRGs to TF2 lasers.",  laser_chart.author), 0, null, null)

        if (lc_player.state == LaserChartPlayerState.Failed) {
            EntFireByHandle(hits_label, "SetText", format("Failed at %0.02f%%", lc_player.finishedPercent * 100), 0, null, null)
        }
        else {
            EntFireByHandle(hits_label, "SetText", format("Hits: %i", lc_player.playerScores[0].hits), 0, null, null)
        }

        if (timescale != 1 || cheats != 0) {
            EntFireByHandle(hits_label, "SetText", format("Cheated", lc_player.playerScores[0].hits), 0, null, null)
        }

        EntFireByHandle(mods_label, "SetText", this.game.playContext.tostring(), 0, null, null)

        local sprite = Sprite(format("laserchart/sprites/%s", laser_chart.image))
        sprite.SetAbsOrigin(Vector(926, 1292, 165))
        this.entities.append(sprite)
    }

    function clear() {
        foreach (entity in this.entities) {
            entity.Kill()
        }
        entities = []
    }
}

module <- Result