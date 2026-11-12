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

// the floating notch is wanted: the active window is fullscreen on the
// island's screen. the control center always opens under the island's
// panel, so a notch on another screen would open it on the wrong one
function gameOnIsland(fullScreen, windowScreen, islandScreen) {
    return fullScreen === true && sameScreen(windowScreen, islandScreen);
}
