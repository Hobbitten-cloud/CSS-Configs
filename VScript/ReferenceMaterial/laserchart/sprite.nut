module <- function(sprite_path) {
    local entity = SpawnEntityFromTable("env_sprite",
    {
        targetname = "sprite_" + sprite_path,
        model = sprite_path,
    })
    Entities.FindByClassname(null, "player").PrecacheModel(sprite_path)
    EntFireByHandle(entity, "ToggleSprite", "", 0, null, null)
    return entity
}