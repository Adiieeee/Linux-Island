.pragma library

// helpers for Alerts.qml: plain functions, no QML, so they can be tested on
// their own

// the clipboard's preview: the first line with something on it, its runs
// of spaces and tabs as one space. the notch has room for one line; the
// rest is cut off with an ellipsis where it's drawn
function preview(text) {
    var lines = String(text || "").split(/\r?\n/);
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].replace(/\s+/g, " ").trim();
        if (line !== "")
            return line;
    }
    return "";
}

// a Bluetooth device's freedesktop icon name (BluezQt's Device.icon:
// "audio-headphones", "input-mouse", "phone"...) as a Material Symbols name
function bluetoothIcon(iconName) {
    var name = String(iconName || "");
    if (/headset|headphone|audio|speaker/.test(name))
        return "headphones";
    if (/mouse/.test(name))
        return "mouse";
    if (/keyboard/.test(name))
        return "keyboard";
    if (/joystick|gaming|gamepad|joypad/.test(name))
        return "sports_esports";
    if (/phone/.test(name))
        return "smartphone";
    if (/computer|laptop/.test(name))
        return "computer";
    return "bluetooth_connected";
}
