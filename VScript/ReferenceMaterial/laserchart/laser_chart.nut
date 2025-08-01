class LaserChart {
    id = ""
	artist = ""
	title = ""
    author = ""
	audio = ""
	image = ""
    objects = null

    constructor(note_chart, laser_chart_objects) {
        this.artist = note_chart.artist
        this.title = note_chart.title
        this.author = note_chart.originalAuthor
        this.audio = note_chart.audio
        this.image = note_chart.bg
        this.objects = laser_chart_objects
    }
}

module <- LaserChart