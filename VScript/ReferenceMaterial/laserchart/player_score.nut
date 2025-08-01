class PlayerScore {
    player = null
    hits = 0
    maxHits = 20
    grade = "SS"
    failed = false

    constructor(player) {
        this.player = player
        this.reset()
    }

    function reset() {
        this.hits = 0
        this.maxHits = 20
        this.grade = "SS"
        this.failed = false
    }

    function addHit() {
        this.hits += 1
        local h = this.hits

        if (this.hits > this.maxHits) {
            this.failed = true
            this.grade = "F"
            return
        }

        if (h == 0) {
            this.grade = "SS"
        }
        else if (h < 3) {
            this.grade = "S"
        }
        else if (h < 6) {
            this.grade = "A"
        }
        else if (h < 12) {
            this.grade = "B"
        }
        else if (h < 16) {
            this.grade = "C"
        }
        else if (h < 21) {
            this.grade = "D"
        }
    }
}

module <- PlayerScore