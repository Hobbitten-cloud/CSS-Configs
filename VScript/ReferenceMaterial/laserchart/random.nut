class LehmerRng {
    seed = 1
    a = 16807
    m = 2147483647
    q = 127773
    r = 2836

    constructor(seed) {
        if (seed <= 0) {
            error("Bad seed")
        }
        this.seed = seed
    }

    function next() {
        local hi = seed / q
        local lo = seed % q
        this.seed = (a * lo) - (r * hi)
        if (this.seed <= 0) {
            this.seed = this.seed + m
        }
        return (this.seed * 1.0) / m
    }
}

module <- LehmerRng