local Laser = require("laser")
local Random = require("random")

class RowConverter {
    notes = null
    playfieldRadius = 300
    constAddRowNotes = 0
    offset = 0
    allowLongNotes = true
    random = null

    constructor(note_chart, play_context) {
        this.notes = note_chart.objects
        this.constAddRowNotes = 0
        this.offset = 0

        if ("rowConverterModifiers" in note_chart) {
            local mods = note_chart.rowConverterModifiers
            if ("constAddRowNotes" in mods) {
                this.constAddRowNotes += mods.constAddRowNotes
            }
            if ("offset" in mods) {
                this.offset = mods.offset
            }
            if ("noLongNote" in mods) {
                this.allowLongNotes = !mods.noLongNote
            }
        }

        if (play_context.noStars) {
            this.allowLongNotes = false
        }
        if (play_context.moreBlades) {
            this.constAddRowNotes += 1
        }
        if (play_context.onlyBlades) {
            this.constAddRowNotes += 2
        }

        local seed = 69133769

        if (play_context.random) {
            local rnd = Random(1 + floor(Time() * 1000))
            seed = floor(rnd.next() * 1000000)
            printl("SEED: " + seed)
        }

        random = Random(seed)
    }

    function randomPoint() {
        local t = 2 * PI * this.random.next()
        local u = RandomFloat(0, 1) + this.random.next()
        local r = u
        if (u > 1) {
            r = 2 - u;
        }
        return {
            x = (r * cos(t)) * playfieldRadius,
            y = (r * sin(t)) * playfieldRadius
        }
    }

    function addLaser(lasers, time, row_notes) {
        if (row_notes == 0) {
            return
        }

        row_notes += this.constAddRowNotes

        local point = randomPoint()
        local angle = this.random.next() * 360

        switch (row_notes) {
            case 1:
                type = LaserType.Large;
                break;
            case 2:
                local second_point = randomPoint()
                lasers.append(Laser(second_point.x, second_point.y, angle, time, LaserType.Small))
                type = LaserType.Small;
                break;
            case 3:
                type = LaserType.SmallBlade;
                break;
            case 4:
                type = LaserType.LargeBlade;
                break;
            default:
                local second_point = randomPoint()
                lasers.append(Laser(second_point.x, second_point.y, (angle - 90) % 360, time, LaserType.Cross))
                type = LaserType.Cross;
                break;
        }

        lasers.append(Laser(point.x, point.y, angle, time, type))
    }

    function convert() {
        local lasers = []

        local time = notes[0].time
        local row_notes = 0
        local star_spawn_rate = 0.1

        foreach (note in notes) {
            if (note.time != time) {
                addLaser(lasers, time, row_notes)
                time = note.time
                row_notes = 0
            }

            if (this.allowLongNotes && ("endTime" in note)) {
                local delta = note.endTime - note.time
                local count = floor(delta / star_spawn_rate)
                if (count > 0) {
                    for (local i = 0; i != count; i++) {
                        local point = randomPoint()
                        lasers.append(Laser(point.x, point.y, this.random.next() * 360, time + (i * star_spawn_rate), LaserType.Star))
                    }
                } else {
                    row_notes += 1
                }
            } else {
                row_notes += 1
            }
        }

        addLaser(lasers, time, row_notes)

        lasers.sort(function(a, b) {
            if (a.time > b.time) return 1
            if (a.time < b.time) return -1
            return 0
        })

        return lasers
    }
}

module <- RowConverter