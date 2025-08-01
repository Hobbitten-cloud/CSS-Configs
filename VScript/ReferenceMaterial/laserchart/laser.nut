enum LaserType {
    Star
    Small,
    Large,
    SmallBlade,
    LargeBlade,
    Cross,
}

enum LaserHitboxType {
    Circle,
    Line
}

class Laser {
    x = 0
    y = 0
    angle = 0
    time = 0
    type = LaserType.Large
    entity = null

    constructor(x, y, angle, time, type) {
        this.x = x
        this.y = y
        this.angle = angle
        this.time = time
        this.type = type
    }

    function parentToEntity(entity) {
        this.entity = entity
    }
}

module <- Laser