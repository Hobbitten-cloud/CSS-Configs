class Timer {
    entity = null
    scope = null

    constructor(refire_time) {
        entity = SpawnEntityFromTable("logic_timer", {
            RefireTime = "timer" + Time().tostring(),
            StartDisabled = "0"
        })

        entity.ValidateScriptScope();
        scope = entity.GetScriptScope();
        scope.references <- [];
        scope.Tick <- function () {
            foreach (ref in references) {
                ref.instance[ref.method]()
            }
        }

        entity.ConnectOutput("OnTimer", "Tick");
    }

    function connect(instance, method) {
        scope.references.append({
            instance = instance,
            method = method
        });
    }

    function kill() {
        entity.Kill()
    }
}

module <- Timer