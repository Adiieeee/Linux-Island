.pragma library

// "Keep the notch over games" helpers for main.qml: plain functions, no QML,
// so they can be tested on their own

// whether a window's screen (TaskManager's ScreenGeometry, a rect in the
// virtual desktop's logical coordinates) is the island's screen. the
// top-left corner is enough: two screens never share it
function sameScreen(windowScreen, islandScreen) {
    if (!windowScreen || !islandScreen)
        return false;
    return Math.round(windowScreen.x) === Math.round(islandScreen.x) && Math.round(windowScreen.y) === Math.round(islandScreen.y);
}

// the floating notch is wanted: a fullscreen window covers the island's
// screen. that follows KWin's rule for keeping a fullscreen window above
// the panels: it's the active window, or the active window is on another
// screen (watching a video fullscreen on one screen while typing on the
// other keeps it on top; the first version wanted the fullscreen window
// active and hid the notch then). only the island's screen counts: the
// control center always opens under the island's panel.
// windows: [{ fullScreen, minimized, screen }] in the tasks model's order;
// activeIndex: the active one's index, or -1 when the tasks model has no
// active window (a Plasma popup, the desktop), taken as "elsewhere"
function gameOnIsland(windows, activeIndex, islandScreen) {
    const covers = w => w && w.fullScreen === true && w.minimized !== true && sameScreen(w.screen, islandScreen);
    if (!windows.some(covers))
        return false;
    const active = activeIndex >= 0 ? windows[activeIndex] : null;
    return !active || covers(active) || !sameScreen(active.screen, islandScreen);
}
