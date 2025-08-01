module <- {
    function connect(event_name, instance, method) {
        if (!(event_name in this)) {
            this[event_name] <- {
                references = [],

                ["OnGameEvent_" + event_name] = function(event_data) {
                    foreach (ref in references) {
                        ref.instance[ref.method](event_data)
                    }
                }
            }

            __CollectGameEventCallbacks(this[event_name])
        }

        this[event_name].references.append({
            instance = instance,
            method = method
        })
    }

    function disconnect(event_name, instance, method) {
        local index_to_remove = -1

        if (!(event_name in this)) {
            printf("[event.nut | Disconnect] Nothing connected to the event: %s.\n", event_name)
            return
        }

        foreach (i, ref in this[event_name].references) {
            if (method == ref.method && instance == ref.instance) {
                index_to_remove = i
                break
            }
        }

        if (index_to_remove == -1) {
            printf("[event.nut | Disconnect] Callback is not connected to the event: %s\n", event_name)
            return
        }

        this[event_name].references.remove(index_to_remove)
    }
}