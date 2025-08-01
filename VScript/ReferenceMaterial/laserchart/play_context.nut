local mod_alias = {
    random = "RD",
    noFail = "NF",
    noStars = "NST",
    moreBlades = "MB",
    onlyBlades = "OB",
    smallHitbox = "SH"
}

local mod_order = [
    "random",
    "noFail",
    "noStars",
    "moreBlades",
    "onlyBlades",
    "smallHitbox",
]

class PlayContext {
    timeRate = 1.0
    laserSpeed = 1.0
    random = false
    noFail = false
    noStars = false
    moreBlades = false
    onlyBlades = false
    smallHitbox = false

    modParams = {
        timeRate = {
            min = 0.25,
            max = 2.55,
            step = 0.05,
            format = "%0.02fx"
        },
        laserSpeed = {
            min = 0.1,
            max = 1.3,
            step = 0.1,
            format = function(v) {
                return ::format("%i%%", v * 100)
            }
        }
    }

    constructor() {
        this.reset()
    }

    function reset() {
        this.timeRate = 1.0
        this.laserSpeed = 1.0
        this.random = false
        this.noFail = false
        this.noStars = false
        this.moreBlades = false
        this.onlyBlades = false
        this.smallHitbox = false
    }

    function _tostring() {
        local str = ""

        if (this.timeRate != 1) {
                str = format("%sMSpeed: %0.02fx ", str, this.timeRate)
        }
        if (this.laserSpeed != 1) {
                str = format("%sLSpeed: %i%% ", str, this.laserSpeed * 100)
        }

        foreach (i, k in mod_order) {
                if (this[k]) {
                    str += mod_alias[k] + " "
                }
        }

        return str
    }
}

module <- PlayContext