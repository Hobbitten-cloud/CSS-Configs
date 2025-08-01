local Sprite = require("sprite")
local RowConverter = require("converters/row")
local LaserChart = require("laser_chart")

class Select {
    game = null
    entities = []

    checkboxes = null
    labels = null
    buttonMaker = null

    constructor(game) {
        this.game = game
        this.buttonMaker = Entities.FindByName(null, "start_chart_maker")
        this.checkboxes = {
            random = Entities.FindByName(null, "mods_random_button")
            noFail = Entities.FindByName(null, "mods_nofail_button")
            noStars = Entities.FindByName(null, "mods_nostars_button")
            moreBlades = Entities.FindByName(null, "mods_moreblades_button")
            onlyBlades = Entities.FindByName(null, "mods_onlyBlades_button")
            smallHitbox = Entities.FindByName(null, "mods_smallhitbox_button")
        }
        this.labels = {
            timeRate = Entities.FindByName(null, "mods_timerate_label")
            laserSpeed = Entities.FindByName(null, "mods_laserspeed_label")
        }
    }

    function removeEntities() {
        foreach (entity in entities) {
            this.entity.Kill()
        }
        this.entities = []
    }

    function removeSprites() {
        local sprite = null
        while (sprite =  Entities.FindByClassname(sprite, "env_sprite")) {
            sprite.Kill()
        }
    }

    function spawnButtons() {
        if (entities.len() != 0) {
            this.removeEntities()
        }
        this.removeSprites()

        local current_position = Vector(-15072, -5232, 288)
        local last_spawned_button = null
        local last_spawned_label = null
        local charts = this.game.noteChartList

        foreach (i, chart in charts) {
            this.buttonMaker.SpawnEntityAtLocation(current_position, Vector(0, 0, 0))

            last_spawned_button = Entities.FindByName(last_spawned_button, "start_chart_button")
            last_spawned_label = Entities.FindByName(last_spawned_label,  "start_chart_label")

            EntFireByHandle(last_spawned_label, "SetText", format("%s\n%s [LV.%i]", chart.artist, chart.title, chart.lv), 0, null, null)
            local sprite = Sprite(format("laserchart/sprites/%s.vmt", chart.id))
            sprite.SetOrigin(current_position + Vector(0, -18, 10))
            sprite.SetAbsAngles(QAngle(0, 90, 0))

            EntityOutputs.AddOutput(last_spawned_button, "OnPressed", "game", "RunScriptCode", format("game.selectState.selectChart(%i)", i), 0, -1)

            entities.append(last_spawned_button)
            entities.append(last_spawned_label)
            entities.append(sprite)

            current_position = current_position + Vector(350, 0, 0)
        }
    }

    function selectChart(chart_index) {
        local chartmeta = this.game.noteChartList[chart_index]
        local note_chart = require(format("packs/%s/%s.nut", chartmeta.packPath, chartmeta.id))
        local play_context = this.game.playContext

        local row_converter = RowConverter(note_chart, play_context)

        local laser_chart = LaserChart(
            note_chart,
            row_converter.convert()
        )

        local players = this.game.players
        local players_copy = []
        foreach (player in players) {
            players_copy.append(player)
        }

        local lc_player = this.game.laserChartPlayer
        lc_player.setPlayContext(play_context)
        lc_player.setPlayers(players_copy)
        lc_player.setChart(laser_chart)
        this.game.setState(GameState.Gameplay)
        this.game.gameplayState.start()
    }

    function setColor(handle, color) {
        NetProps.SetPropInt(handle, "m_clrRender", color)
    }

    function setDefaults() {
        local play_context = this.game.playContext
        play_context.reset()

        foreach (k, v in play_context) {
            if (typeof v == "bool") {
                setColor(this.checkboxes[k], 0xffffffff)
            }
        }
    }

    function checkboxPressed(id) {
        local play_context = this.game.playContext
        local checkbox = checkboxes[id]
        local active = play_context[id]
        if (active) {
            setColor(checkbox, 0xffffffff)
        }
        else {
            setColor(checkbox, 0xff00ff00)
        }

        play_context[id] = !play_context[id]
    }

    function round(x, to) {
        if ((x / to) % 1.0 < 0.5) {
            return floor(x / to) * to
        }
        else {
            return ceil(x / to) * to
        }
    }

    function stepperIncrease(id) {
        this.stepperPressed(id, 1)
    }

    function stepperDecrease(id) {
        this.stepperPressed(id, -1)
    }

    function stepperPressed(id, direction) {
        local play_context = this.game.playContext
        local value = play_context[id]
        local label = labels[id]
        local params = play_context.modParams[id]

        value += direction * params.step
        value = round(value, params.step)

        if (value < params.min) {
            value = params.min
        }
        else if (value > params.max) {
            value = params.max
        }

        play_context[id] = value

        if (typeof params.format == "function") {
            label.__KeyValueFromString("message", params.format(value))
        }
        else {
            label.__KeyValueFromString("message", format(params.format, value))
        }
    }
}

module <- Select