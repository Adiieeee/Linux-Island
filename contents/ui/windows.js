.pragma library

// picking the window to bring forward, for the media card (a player) and
// main.qml (a notification's app): a plain function over a
// TaskManager.TasksModel, so it can be tested with a stand-in model

// the index of the window to activate, or null. roles is
// TaskManager.AbstractTasksModel (for its role names). the windows of the
// process (pid > 0), else of the app: its desktop entry against AppId, or
// failing that its name against AppName. with several, the one demanding
// attention (it just asked to be shown), else the one used last
function pick(tasks, roles, pid, entry, name) {
    var byPid = [], byApp = [];
    var wantEntry = String(entry || "").toLowerCase();
    var wantName = String(name || "").toLowerCase();
    for (var i = 0; i < tasks.count; i++) {
        var idx = tasks.index(i, 0);
        if (!tasks.data(idx, roles.IsWindow))
            continue;
        var appId = String(tasks.data(idx, roles.AppId) || "").toLowerCase();
        var appName = String(tasks.data(idx, roles.AppName) || "").toLowerCase();
        if (pid > 0 && Number(tasks.data(idx, roles.AppPid)) === pid)
            byPid.push(idx);
        else if ((wantEntry !== "" && (appId === wantEntry || appId.indexOf(wantEntry) >= 0)) || (wantName !== "" && appName === wantName))
            byApp.push(idx);
    }
    var found = byPid.length > 0 ? byPid : byApp;
    if (found.length === 0)
        return null;
    var best = found[0];
    for (var j = 0; j < found.length; j++) {
        var cand = found[j];
        if (tasks.data(cand, roles.IsDemandingAttention)) {
            best = cand;
            break;
        }
        var t = tasks.data(cand, roles.LastActivated);
        var bt = tasks.data(best, roles.LastActivated);
        if (t && (!bt || new Date(t) > new Date(bt)))
            best = cand;
    }
    return best;
}
