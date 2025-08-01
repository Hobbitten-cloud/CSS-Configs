function require(path) { // cuz I love lua
    local t = {}
    IncludeScript("laserchart/" + path, t)

    if (!("module" in t)) {
        return t
    }

    local module = t.module
    return module
}

::require <- require
::GameEvents <- require("event")

local PlayContext = require("play_context")
local SelectState = require("states/select")
local GameplayState = require("states/gameplay")
local ResultState = require("states/result")
local LaserChartPlayer = require("laser_chart_player")
local Timer = require("timer")

enum GameState {
    Select,
    Gameplay,
    Result
}

class Game {
    playContext = null
    laserChartPlayer = null

    selectState = null
    gameplayState = null
    resultState = null

    noteChartList = null

    gameState = GameState.Select

    tickTimer = Timer(0)
    players = []

    constructor() {
        this.playContext = PlayContext()
        this.laserChartPlayer = LaserChartPlayer(this)
        this.selectState = SelectState(this)
        this.gameplayState = GameplayState(this)
        this.resultState = ResultState(this)

        this.tickTimer.connect(this, "update")
    }

    function load() {
        local servercommand = Entities.FindByClassname(null, "point_servercommand")

        this.noteChartList = []

        local packs = require("packs/packs")
        foreach (path in packs) {
            local list = require(format("packs/%s/list.nut", path))
            foreach (entry in list) {
                entry.packPath <- path
                this.noteChartList.append(entry)
            }
        }

        this.noteChartList.sort(function(a, b) {
            if (a.lv > b.lv) return 1
            if (a.lv < b.lv) return -1
            return 0
        })

        this.findPlayers()
        this.selectState.spawnButtons()
    }

    function update() {
        switch(this.gameState) {
            case GameState.Select:
                break
            case GameState.Gameplay:
                this.gameplayState.update()
                break
            case GameState.Result:
                break
        }
    }

    function setState(game_state) {
        this.gameState = game_state
    }

    function findPlayers() {
        this.players = []
        local max_players = MaxClients().tointeger()
        for (local i = 1; i <= max_players ; i++)
        {
            local player = PlayerInstanceFromIndex(i)
            if (player)  {
                this.players.append(player)
            }
        }
    }
}

function createGame() {
    game <- Game()
    game.load()
}