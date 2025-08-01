local Audio = require("audio")
local Laser = require("laser")
local Text = require("text")
local Sprite = require("sprite")
local PlayerScore = require("player_score")

local collision = require("collision")

enum LaserChartPlayerState {
    Playing,
    Failed,
    Finished
}

class LaserChartPlayer {
    game = null

    timeRate = 1
    offset = -0.032
    playerHitboxRadius = 24.5
    hitboxBladeMultiplier = 1.4
    prepareTime = 0.5

    playfieldSpawnCenter = Vector(512, -512, 3100)
    playfieldHeightLimit = 0 + 0 // MAX_Z + PLAYER_VIEWHEIGHT
    playfieldRadius = 300
    laserSpeed = 0

    state = LaserChartPlayerState.Playing
    finishedPercent = 0
    noFail = false
    noOneAlive = false

    music = null
    statusText = null

    laserChart = null
    laserChartObjects = null

    playerScores = []

    startTime = 0
    chartDuration = 0
    currentLaserObjectIndex = 0
    spawnedLasers = null
    spawnedLaserIndexRemovalList = null

    laserMakers = {}
    laserEntityState = {}
    laserEntityWorldName = {}
    laserHitbox = {}
    lastSpawnedLaserEntity = {}

    loaded = false

    constructor(game) {
        this.game = game

        this.laserMakers = {
            [LaserType.Small] = Entities.FindByName(null, "laser_small_maker"),
            [LaserType.Large] = Entities.FindByName(null, "laser_large_maker"),
            [LaserType.SmallBlade] = Entities.FindByName(null, "laser_blade_small_maker"),
            [LaserType.LargeBlade] = Entities.FindByName(null, "laser_blade_large_maker"),
            [LaserType.Cross] = Entities.FindByName(null, "laser_cross_maker"),
            [LaserType.Star] = Entities.FindByName(null, "laser_star_maker")
        }

        this.lastSpawnedLaserEntity = {
            [LaserType.Small] = null,
            [LaserType.Large] = null,
            [LaserType.SmallBlade] = null,
            [LaserType.LargeBlade] = null,
            [LaserType.Cross] = null,
            [LaserType.Star] = null,
        }

        this.laserHitbox = {
            [LaserType.Small] = {
                type = LaserHitboxType.Circle
                radius = 40
            },
            [LaserType.Large] = {
                type = LaserHitboxType.Circle
                radius = 52
            },
            [LaserType.SmallBlade] = {
                type = LaserHitboxType.Line
                length = 320
            },
            [LaserType.LargeBlade] = {
                type = LaserHitboxType.Line
                length = 1024
            },
            [LaserType.Cross] = {
                type = LaserHitboxType.Line
                length = 1024
            },
            [LaserType.Star] = {
                type = LaserHitboxType.Circle
                radius = 16
            },
        }

        this.laserEntityWorldName = {
            [LaserType.Small] = "laser_small",
            [LaserType.Large] = "laser_large",
            [LaserType.SmallBlade] = "laser_blade_small",
            [LaserType.LargeBlade] = "laser_blade_large",
            [LaserType.Cross] = "laser_cross",
            [LaserType.Star] = "laser_star",
        }
    }

    function load() {
        this.state = LaserChartPlayerState.Playing
        this.noOneAlive = false
        this.finishedPercent = 0
        this.chartDuration = 0

        this.music = Audio(this.laserChart.audio)
        this.statusText = Text(-1, 0.87, Vector(209, 209, 209), 4, false, "Status")

        this.currentLaserObjectIndex = 0
        this.spawnedLasers = []
        this.spawnedLaserIndexRemovalList = []

        foreach(score in this.playerScores) {
            score.reset()
        }

        this.chartDuration = (this.laserChartObjects[this.laserChartObjects.len() - 1].time) * this.timeRate
        this.music.play(this.timeRate, this.prepareTime)
        this.startTime = Time() + this.prepareTime

        this.loaded = true
    }

    function unload() {
        this.loaded = false

        this.music.stop()
        this.music.kill()
        this.statusText.kill()

        foreach (laser_data in this.spawnedLasers) {
            laser_data.entity.Kill()
        }
        this.spawnedLasers = []
    }

    function setLaserSpeed(multiplier) {
        this.laserSpeed = (playfieldSpawnCenter.z - playfieldHeightLimit) * multiplier
    }

    function setChart(laser_chart) {
        this.laserChart = laser_chart
        this.laserChartObjects = laser_chart.objects
    }

    function setPlayContext(play_context) {
        this.timeRate = play_context.timeRate
        this.noFail = play_context.noFail
        this.setLaserSpeed(play_context.laserSpeed)

        if (play_context.smallHitbox) {
            this.hitboxBladeMultiplier = 1
        }
        else {
            this.hitboxBladeMultiplier = 1.4
        }
    }

    function setPlayers(players) {
        foreach(player in players) {
            this.playerScores.append(PlayerScore(player))
        }
    }

    function checkHit(hitbox, laser_entity) {
        local hit = false
        local someone_is_alive = false

        foreach(player_score in this.playerScores) {
            local player = player_score.player
            switch(hitbox.type) {
                case LaserHitboxType.Circle:
                    hit = collision.circleIntersection(player.GetOrigin(), this.playerHitboxRadius, hitbox.radius, laser_entity.GetOrigin())
                    break;
                case LaserHitboxType.Line:
                    // NOTE: Do not rotate lasers in hammer, otherwise the initial angle on the spawn will be incorrect
                    hit = collision.lineIntersection(
                        player.GetOrigin(),
                        this.playerHitboxRadius * this.hitboxBladeMultiplier,
                        laser_entity.GetOrigin(),
                        hitbox.length,
                        laser_entity.GetAbsAngles()
                    )
                    break;
                default:
                    printl("Skipping unknown laser hitbox")
                    break
            }

            if (hit) {
                player_score.addHit()
                player.TakeDamage(1, 1, null)
                player.SetHealth(player.GetMaxHealth())
            }

            someone_is_alive = someone_is_alive || !player_score.failed
        }

        this.noOneAlive = !someone_is_alive
    }

    function showStatus() {
        local percent = this.finishedPercent * 100

        foreach(player_score in this.playerScores) {
            local hits = player_score.hits
            local max = player_score.maxHits
            local grade = player_score.grade
            if (this.noFail) {
                this.statusText.setText(format("Hits: %i    Grade: %s\n%0.01f%%", hits, grade, percent))
            }
            else {
                this.statusText.setText(format("Hits: %i/%i    Grade: %s\n%0.01f%%", hits, max, grade, percent))
            }
            this.statusText.display(player_score.player)
        }
    }

    function update() {
        if (!this.loaded) {
            return
        }

        foreach(i, laser_data in this.spawnedLasers) {
            local laser_origin = laser_data.entity.GetOrigin()

            if (laser_origin.z < this.playfieldHeightLimit) {
                if (this.checkHit(this.laserHitbox[laser_data.type], laser_data.entity)) {
                    return
                }
                this.spawnedLaserIndexRemovalList.append(i)
            }
        }

        if (this.spawnedLaserIndexRemovalList.len() != 0) {
            for (local i = this.spawnedLaserIndexRemovalList.len() - 1; i >= 0; i--) {
                this.spawnedLasers[i].entity.Kill()
                this.spawnedLasers.remove(i)
            }
            this.spawnedLaserIndexRemovalList = []
        }

        local current_time = (Time() - this.startTime) * this.timeRate
        this.finishedPercent = current_time / (this.chartDuration / this.timeRate)

        if (this.finishedPercent < 0) {
            this.finishedPercent = 0
        }
        if (this.finishedPercent > 1) {
            this.finishedPercent = 1
        }

        for (; this.currentLaserObjectIndex != this.laserChartObjects.len();) {
            local laser_data = this.laserChartObjects[this.currentLaserObjectIndex]

            if (laser_data.time > current_time + this.offset) {
                break
            }

            local type = laser_data.type

            this.laserMakers[type].SpawnEntityAtLocation(
                this.playfieldSpawnCenter + Vector(laser_data.x, laser_data.y, 0),
                Vector(0, laser_data.angle, 0)
            )

            local new_laser = Entities.FindByName(
                this.lastSpawnedLaserEntity[type],
                this.laserEntityWorldName[type]
            )

            new_laser.__KeyValueFromFloat("speed", this.laserSpeed);
            EntFireByHandle(new_laser, "Open", "", 0, null, null)

            laser_data.parentToEntity(new_laser)
            this.spawnedLasers.append(laser_data)
            this.currentLaserObjectIndex += 1
            this.lastSpawnedLaserEntity[type] = new_laser
        }

        this.showStatus()

        if (current_time > this.laserChartObjects[this.laserChartObjects.len() - 1].time + 1.6 && this.spawnedLasers.len() == 0) {
            this.state = LaserChartPlayerState.Finished
            this.unload()
            return
        }

        if (!this.noFail && this.noOneAlive) {
            this.state = LaserChartPlayerState.Failed
            this.unload()
            return
        }
    }
}

module <- LaserChartPlayer