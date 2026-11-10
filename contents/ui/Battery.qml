import QtQuick
import org.kde.plasma.plasma5support as P5Support
import "."

// batería vía motor de energía de plasma
// en desktop sin batería "Has Battery" igual da true con un Battery0 fantasma
// a 0%, pero State queda "Unknown": eso es lo que de verdad delata que no hay
Row {
    id: root
    spacing: 4

    P5Support.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: ["Battery"]
    }

    readonly property var bat: pmSource.data["Battery"] ?? ({})
    readonly property bool present: (bat["Has Battery"] ?? false) && bat["State"] !== "Unknown"
    readonly property int percent: bat["Percent"] ?? 0
    readonly property bool charging: (bat["State"] ?? "") === "Charging"

    visible: present

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: {
            if (root.charging)
                return Icons.batCharging;
            const p = root.percent;
            if (p > 85)
                return Icons.batFull;
            if (p > 60)
                return Icons.bat3q;
            if (p > 35)
                return Icons.batHalf;
            if (p > 15)
                return Icons.batQuarter;
            return Icons.batEmpty;
        }
        color: root.charging ? Theme.primary : root.percent <= 15 ? Theme.error : Theme.fg
        font.family: Theme.fontIcons
        font.pixelSize: 18
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.percent
        color: Theme.fgVariant
        font.family: Theme.font
        font.pixelSize: Theme.labelMedium
    }
}
