pragma Singleton

import QtQuick
import org.kde.plasma.plasma5support as P5Support

// correr un comando sin esperar respuesta (bloquear, abrir carpeta, subir volumen)
// los que necesitan leer la salida se arman su propio DataSource
QtObject {
    id: root

    // tipada, no var: con var el gc de js la puede liberar mientras c++ la usa
    readonly property P5Support.DataSource source: P5Support.DataSource {
        engine: "executable"
        connectedSources: []
        onNewData: cmd => disconnectSource(cmd)
    }

    function run(cmd: string): void {
        root.source.connectSource(cmd);
    }
}
