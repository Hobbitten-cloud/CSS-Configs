class Gameplay {
    game = null
    laserChartPlayer = null
    playfieldTeleport = null
    speedMod = null

    constructor(game) {
        this.game = game
        this.laserChartPlayer = game.laserChartPlayer
        this.playfieldTeleport = Entities.FindByName(null, "playfield_teleport")

        this.speedMod = SpawnEntityFromTable("player_speedmod", {
            targetname = "speedmod",
        })
    }

    function start() {
        this.teleportAllPlayers()
        this.laserChartPlayer.load()
    }

    function retry() {
        this.game.setState(GameState.Gameplay)

        if (this.laserChartPlayer.loaded) {
            this.laserChartPlayer.unload()
        }
        this.teleportAllPlayers()
        this.laserChartPlayer.load()
    }

    function quit() {
        this.game.setState(GameState.Result)
        this.laserChartPlayer.unload()

        local teleport = Entities.FindByName(null, "song_select_teleport")
        foreach (score in this.laserChartPlayer.playerScores) {
            score.player.SetOrigin(teleport.GetOrigin() + Vector(0, 0, 8))
            score.player.SnapEyeAngles(teleport.GetAbsAngles())
        }
    }

    function playing() {
        local player_scores = this.laserChartPlayer.playerScores
        local playfield_center = this.laserChartPlayer.playfieldSpawnCenter
        local max_distance = this.laserChartPlayer.playfieldRadius + 15
        foreach (score in player_scores) {
            local player = score.player
            local player_origin = player.GetOrigin()
            local distance = sqrt(pow(playfield_center.x - player_origin.x, 2) + pow(playfield_center.y - player_origin.y, 2))
            if (distance > max_distance) {
                player.SetOrigin(this.playfieldTeleport.GetOrigin() + Vector(0, 0, 8))
                player.SnapEyeAngles(QAngle(-90, 0, 0))
            }
        }
    }

    function update() {
        this.laserChartPlayer.update()

        switch(this.laserChartPlayer.state) {
            case LaserChartPlayerState.Playing:
                playing()
                break;
            case LaserChartPlayerState.Finished:
                this.game.setState(GameState.Result)
                this.game.resultState.showScores()
                break;
            case LaserChartPlayerState.Failed:
                this.game.setState(GameState.Result)
                this.game.resultState.showScores()
                break;
        }
    }

    function teleportAllPlayers() {
        local player_scores = this.laserChartPlayer.playerScores
        foreach (score in player_scores) {
            local player = score.player
            player.SetOrigin(this.playfieldTeleport.GetOrigin() + Vector(0, 0, 8))
            player.SnapEyeAngles(QAngle(-90, 0, 0))
            EntFireByHandle(this.speedMod, "ModifySpeed", "1.3", 0, score.player, score.player)
        }
    }
}

module <- Gameplay