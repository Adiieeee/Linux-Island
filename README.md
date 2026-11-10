# Isla — versión Plasma

Port de la isla de Quickshell (`~/.config/quickshell/`) a un widget de KDE
Plasma. Mismo estilo Nothing OS, mismas animaciones, mismo contenido.

## Instalar

Ya está copiado en `~/.local/share/plasma/plasmoids/org.omar.nothingisland/`.
Para que Plasma lo vea:

```bash
kquitapp6 plasmashell && kstart plasmashell
```

Después: clic derecho en el escritorio o en un panel → "Añadir widgets" →
buscar **Nothing Dynamic Island**.

## En su propio panel (recomendado)

Metida en un panel compartido, la isla queda apretada entre los demás
widgets. Mejor darle un panel para ella sola:

Clic derecho en el escritorio → **Añadir panel** → **Isla**.

Eso usa la plantilla de
`~/.local/share/plasma/layout-templates/org.omar.island.panel/`, que crea
un panel normal de Plasma con tres ajustes que lo vuelven invisible:

| Ajuste | Para qué |
| --- | --- |
| `backgroundHints = 4` | Apaga el fondo. No se ve el marco gris de Plasma. |
| `lengthMode = "fit"` | El panel mide lo que mide la isla, nada más. |
| `alignment = "center"` | Queda centrado arriba. |

Es la misma receta del panel de wavetask. **Ojo con `lengthMode`**: va como
texto (`"fit"`), no como número. Con `1` la propiedad no toma y el panel se
queda cruzando toda la pantalla.

Después de crearlo conviene sacar la isla del panel donde estuviera antes,
o van a quedar dos.

## Crecer en el lugar: probado y no salió

`Island.qml` es el intento: una sola superficie que anima su propio ancho y
alto, igual que en Hyprland, y le pide a plasmashell agrandar el panel al
abrirse. **Funciona fuera de Plasma** (se probó con `qml-qt6` y se ve
exactamente como la isla de Hyprland), pero adentro de un panel se pelea
con tres cosas del propio Plasma:

1. **El panel reserva la altura.** Al crecer de 44 a 460, todas las
   ventanas se corren hacia abajo. Los únicos modos que evitan reservar son
   `autohide` y `dodgewindows`, y los dos esconden la isla, que es peor.
   `windowsgobelow` no existe en Plasma 6: se acepta el valor y queda en
   `none`.
2. **El panel centra el widget a lo alto.** Con el panel en 460 la píldora
   queda flotando en el medio, no arriba, así que la isla no crece hacia
   abajo: crece para los dos lados.
3. **El panel dibuja su fondo igual.** Con `backgroundHints = 4` sigue
   pintando `panel-background.svg`, que es negro opaco. Al crecer aparece un
   bloque negro de 460 px en vez de una isla flotando.

El ancho **sí** funciona solo: con `lengthMode = "fit"` el panel se estira y
se encoge detrás de la isla sin que nadie haga nada.

Por eso quedó el popup de Plasma. `Island.qml` sigue en el repo, sin usar,
para retomarlo si algún día Plasma deja fijar la alineación del widget y
saltarse el fondo del panel.

## Qué cambia respecto de la versión de Hyprland

| Cosa | Cómo quedó |
| --- | --- |
| Forma | Píldora en el panel + panel emergente al hacer clic. Plasma no deja una ventana flotante libre como layer-shell. |
| Bandeja del sistema | Se quitó. La bandeja la maneja `plasmashell` y no se puede reimplementar dentro de un widget. |
| Workspaces | Escritorios virtuales de KWin en vez de los de Hyprland. |
| Notificaciones | Se lee el historial de Plasma; el widget no es el servidor. "Silenciar" activa el No Molestar de Plasma. |
| Modo café | Lo hace `contents/code/coffee.py`, ver abajo. |
| Bloquear | `org.freedesktop.ScreenSaver` en vez de `hyprlock`. |
| Grabación | `spectacle --record=s` en vez de `wf-recorder`, que solo anda en wlroots. No se elige monitor ni FPS desde acá. |
| Carátulas | Plasma ya entrega la URL resuelta; se fue el servicio `Cover`. |
| Sonido | `wpctl` + `pactl` cada segundo. El módulo nativo de Plasma lista los dispositivos pero no expone desde QML cuál está activo. |
| Dock y Configuración | Sacados a pedido. |

## Qué se mantiene igual

Reloj, clima, red, bluetooth, volumen con techo real de 150 % y barra roja
de boost, batería, reproductor con carátula y onda, medidores de CPU / RAM /
GPU con el fuego rojo, grabación, modo café, franja de notificación, y los
paneles internos de wifi, bluetooth, sonido, notificaciones y grabación.

Todos los tokens de diseño siguen en `Theme.qml`, sin tocar.

## Preferencias del widget

Clic derecho en la isla → "Configurar Isla…". Lo que hay:

- **Idioma**: automático (el del sistema), español o inglés. Cambia solo los
  textos de la isla, no el escritorio.
- **Hora**: 24 horas o 12 con AM/PM.
- **Medidores**: la RAM en porcentaje (por defecto) o cuánta se está usando
  sobre el total, "7.8/31".
- **Mostrar en la isla chica**: escritorios, clima, reloj, red, volumen,
  batería.
- **Reproductor**: mostrar o no el minireproductor mientras suena algo.

Los valores viven en `contents/config/main.xml`. Para agregar uno nuevo hay
que tocar cuatro archivos: ese, `ConfigGeneral.qml` (la casilla),
`main.qml` (el `Binding` que lo copia) y `Cfg.qml` (donde lo lee el resto).
Los singletons de QML no ven `Plasmoid.configuration`, por eso el rodeo.

### Colores y tipografías

Dos páginas más en las preferencias, `ConfigColores.qml` y
`ConfigTipografias.qml`. Se eligen cuatro colores —fondo, tarjetas,
"encendido" (la tarjeta invertida) y alerta—, las dos tipografías y el
color del texto. Cada página tiene su botón de restablecer, que se apaga
solo cuando ya está todo como vino de fábrica.

Plasma guarda los valores en `plasma-org.kde.plasma.desktop-appletsrc`, así
que sobreviven al reinicio sin que el widget haga nada.

Tres detalles del diseño:

- **Se piden cuatro colores, no doce.** `Theme.qml` saca los escalones
  intermedios (`surfaceAlt`, `surfaceHigh`, `surfaceTop`, `fgDim`,
  `fgFaint`, `outline`) mezclando los elegidos con el color del texto o con
  el fondo, en proporciones fijas. Con los valores de fábrica dan
  exactamente los grises de antes, comprobado token por token; y si el
  usuario pone un fondo claro la rampa se acomoda sola, porque es una
  interpolación y no depende de que el fondo sea oscuro.
- **El texto de la tarjeta invertida se decide por brillo**, no está fijo en
  negro: si alguien deja esa tarjeta oscura, el texto pasa a blanco solo.
- **Los valores de fábrica no se repiten en el código.** Se declaran las
  propiedades `cfg_<clave>Default` vacías en la página y Plasma las rellena
  desde `main.xml`. Es lo mismo que hace el fondo de pantalla de KDE en
  `/usr/share/plasma/wallpapers/org.kde.slideshow/contents/ui/config.qml`.

**Ojo con el reset**: al elegir un color o una fuente, el `ColorButton` y el
`ComboBox` se escriben su propio valor y eso deja sin efecto el binding que
los ataba a la configuración. Por eso `restablecer()` les devuelve el valor
a mano además de escribir la clave; si no, el reset cambiaba lo guardado
pero el control seguía mostrando lo viejo.

La fuente de los iconos **no** se puede cambiar, a propósito: son ligaduras
de Material Symbols y con cualquier otra fuente los iconos vuelven a salir
como el nombre en texto.

**Cambiar el idioma no traducía estas dos páginas al toque.** `Cfg.esp` es
el idioma ya aplicado —lo pisa el `Binding` de `main.qml`, que solo corre
después de Aceptar—, no el que se está por elegir en el combo de la página
General. `ConfigGeneral.qml` ya resolvía esto con su propio `page.esp` en
vivo; a Colores y Tipografías se les había quedado colgado el de `Cfg`, así
que cambiar el idioma y saltar de pestaña sin aceptar las dejaba en el
idioma viejo. Se arregla igual: cada página declara su propio
`cfg_lang`, que Plasma conecta al mismo `KConfigPropertyMap` en vivo que
usa la página General (confirmado en el comentario `// type:
KConfigPropertyMap` de
`/usr/share/plasma/shells/org.kde.plasma.desktop/contents/configuration/AppletConfiguration.qml`),
y calcula `esp` de ese valor en vez de importar el singleton.

## Las tipografías van adentro del widget

`contents/fonts/` lleva las tres: `SpaceGrotesk.ttf`,
`ndot-47-inspired-by-nothing.otf` y `MaterialSymbolsRounded.ttf`.
`Theme.qml` las carga con `FontLoader` y usa el nombre que devuelve, en vez
de pedirlas por nombre al sistema.

Esto fue el primer informe de fallos de la KDE Store: pedidas por nombre,
en una máquina donde no estaban instaladas los iconos salían como texto
(`skip_previous`, `local_fire_department`), los números como cuadros vacíos,
y esos cuadros son los "bordes negros" que se veían.

Un detalle que podría haber salido mal y no: `SpaceGrotesk.ttf` es una
fuente variable cuya familia heredada es `Space Grotesk Light`. Si
`FontLoader` hubiera devuelto ese nombre, todo el texto habría quedado más
fino que antes. Devuelve `Space Grotesk`, comprobado.

## Cuidado al tocar esto (tumbó plasmashell una vez)

El widget corre **dentro** de plasmashell: un error acá se lleva puesto todo
el escritorio. Dos reglas que salieron de una tanda de cinco caídas seguidas
(SIGSEGV en el recolector de basura de QML, `QV4::MarkStack::drain`):

1. **Nunca `property var` para guardar un objeto creado ahí mismo.** Con
   `var`, el objeto queda en manos del recolector de JS y lo puede liberar
   mientras C++ todavía lo usa. Va tipado:
   `readonly property P5Support.DataSource source: P5Support.DataSource {…}`.
2. **No guardar callbacks que crucen a C++ y vuelvan.** El `Exec` original
   guardaba funciones en un diccionario y las llamaba desde `onNewData`.
   Ahora `Exec.run` solo dispara y olvida; el que necesita leer la salida
   se arma su propio `DataSource` y reparte por nombre de comando.

3. **Nada de `MultiEffect` sobre una capa, tampoco acá.** El
   `ExpandedPanel` desenfocaba el contenido con `layer.enabled` + blur
   cuando se abría un panel (wifi, bluetooth, calendario…): la misma
   receta que revienta el proceso, puesta en el archivo de al lado. Ya no
   está. Ahora el contenido se apaga y se achica un poquito, y el velo
   negro tapa la isla entera. De paso se fue el cuadro que se veía marcado
   a 14 px del borde: la capa y el velo cubrían solo el recuadro interior,
   y el marco de alrededor quedaba sin oscurecer.

Y una de peso: **no sondear seguido**. Se llegó a lanzar cinco procesos por
segundo desde adentro de plasmashell. Ahora el volumen se mira cada 1 s (un
comando), el sistema cada 3 s, la red cada 8 s, y las listas largas (redes
cercanas, aparatos de audio y bluetooth) solo mientras el panel está
abierto, contando con `watchers`.

## Panel de apagado

El botón con el icono de encendido, en la fila de abajo de la isla, abre un
panel con: bloquear, cerrar sesión, suspender, hibernar, reiniciar y apagar.
Suspender e hibernar solo aparecen si el equipo puede (se le pregunta a
`org.freedesktop.PowerManagement` con `CanSuspend` y `CanHibernate`).

Las cuatro opciones de peso —cerrar sesión, hibernar, reiniciar y apagar—
**piden confirmación en la misma fila**: se abre hacia abajo y hay que
tocar "SÍ". Un clic de más en una isla chica no puede tirar la máquina
abajo.

Nada se hace con `systemctl`: se le pide a Plasma por DBus
(`org.kde.Shutdown` para sesión/reinicio/apagado,
`org.freedesktop.PowerManagement` para suspender e hibernar,
`org.freedesktop.ScreenSaver` para bloquear). Es lo mismo que hace el menú
de apagado de KDE, así que avisa a los programas para que guarden y cierra
la sesión ordenada en vez de matar todo de golpe.

## El fogonazo de los botones al pasar el mouse

Los botones redondos (candado, campana, apagado) y las filas de los paneles
se encendían de golpe y **después** bajaban a un gris tenue. No era la
animación: era mezclar tipos de color.

El reposo era un gris opaco (`#161616`) y el hover un blanco translúcido
(`rgba(255,255,255,0.10)`). Al animar de uno al otro, la mitad del camino
es `rgba(128,128,128,0.55)` —un gris claro— y eso es el fogonazo.

Dos reglas para no repetirlo:

- Si el reposo es **opaco**, el hover también: `surfaceAlt` → `surfaceHigh`
  → `surfaceTop`.
- Si el reposo es **transparente**, se usa `Qt.alpha(Theme.fg, 0)` en vez de
  `"transparent"`: así los dos extremos son el mismo blanco y lo único que
  se mueve es la transparencia.

## Otros gotchas

- **`Plasma5Support.DataSource` ya corre el comando dentro de un shell.**
  Envolverlo uno mismo en `sh -c "…"` lo pasa por DOS shells: el de afuera
  se come los `$h`, `$n` y `$(…)` antes de que llegue el de adentro, y el
  comando revienta en silencio (el CPU mostraba siempre 0 % y 0°). Se pasa
  el script pelado, sin `sh -c` ni comillas de más.
- **`VirtualDesktopInfo` es de solo lectura.** No tiene método para cambiar
  de escritorio. Se cambia por DBus, escribiendo la propiedad `current` de
  KWin directo: `qdbus org.kde.KWin /VirtualDesktopManager
  org.kde.KWin.VirtualDesktopManager.current "<uuid>"`. Los ids que devuelve
  `VirtualDesktopInfo.desktopIds` son esos mismos UUID.
- **La altura de `ExpandedPanel` no puede ser un número fijo como en
  Hyprland.** Ahí la isla crece con resorte a mano; acá Plasma dibuja el
  popup del tamaño que se le pida. Con `Theme.expandedHeight` fijo (pensado
  para la versión con bandeja de apps, que no existe en este port) sobraba
  una franja negra abajo. Ahora sale de `mainColumn.implicitHeight`, el
  alto real del contenido, y `main.qml` fija `Layout.maximumHeight` igual
  al mínimo para que Plasma no lo estire.
- **Plasma recuerda el tamaño del popup** en `popupHeight` / `popupWidth`,
  dentro de `[Containments][N][Applets][M][Configuration]` en
  `~/.config/plasma-org.kde.plasma.desktop-appletsrc`. Ese valor le gana al
  `implicitHeight` nuevo: si se cambia el alto de la isla hay que **parar
  plasmashell, borrar esas dos claves y volver a arrancarlo**, o el tamaño
  viejo sigue mandando (y la franja negra vuelve aunque el código esté bien).
- **Un hijo con `anchors.fill` adentro de un `Row` deja el Row sin
  funcionar** — desaparece todo su contenido. Pasó al meter el `MouseArea`
  de la rueda dentro de `Workspaces`, que era un `Row`: se fueron los
  puntos de escritorio. Ahora la raíz es un `Item` con el `Row` adentro y
  el `MouseArea` al lado.
- **Para redondear una imagen va `Kirigami.ShadowedImage`, no
  `Rectangle { radius; clip: true }`.** `clip` recorta al rectángulo, no a
  la forma redondeada, así que la carátula tapaba las esquinas y se veía
  cuadrada tanto en la tarjeta del reproductor como en el minireproductor.
  `ShadowedImage` redondea de verdad, es la primitiva que usa el propio
  Plasma y no tiene nada que ver con el `MultiEffect` que revienta el
  proceso.
- **Un elemento invisible sigue ocupando su lugar para los anclajes.** En
  `Meters`, el número se anclaba a `tempRow.left` con margen 8 solo si
  había temperatura, y 0 si no: como la fila de la RAM no tiene
  temperatura pero `tempRow` sigue anclada a la derecha con su ancho, el
  número de la RAM quedaba 8 px corrido y su barra 8 px más larga que las
  otras dos. El margen va siempre igual. Por lo mismo, el ancho de la
  columna del número se decide una sola vez en el `Column` de arriba
  (`anchoValor`) y no fila por fila: si no, con la RAM en modo "7.8/31"
  esa fila se ensancha sola y las barras vuelven a medir distinto.
- **En NDOT 47 el `1` mide 888 y todos los demás dígitos 1333.** No es una
  fuente de ancho fijo, así que el reloj cambiaba de ancho cada segundo y
  el botón del calendario, que va pegado a su derecha, se movía solo. Los
  dos textos del reloj reservan ancho con un `TextMetrics` cuyo molde es el
  mismo texto con todos los dígitos en cero (el `0` es de los anchos).

## Cosas que estaban rotas y ya no

Cuatro cosas se habían traído mal del port. Todas encontradas revisando qué
API expone Plasma de verdad, no qué API tenía Quickshell.

### El reproductor no dejaba adelantar

`MediaCard` llamaba a `SetPosition(trackId, …)`. **En el MPRIS de Plasma no
existe ninguno de los dos**: el reproductor solo expone `Seek(offset)`, que
mueve una cantidad *relativa* a donde está sonando, en microsegundos. Ahora
se calcula la diferencia entre el punto donde se hizo clic y la posición
actual, y se manda esa resta.

### El modo café no inhibía nada

Dos problemas encadenados:

1. `systemd-inhibit --what=idle` registra un inhibidor de **logind**, y
   PowerDevil no lo mira para apagar la pantalla: usa su propio contador de
   inactividad. Servía para que no se suspendiera, no para que no se
   apagara la pantalla.
2. Cambiarlo por un `qdbus` tampoco alcanzaba: **KDE ata cada inhibición a
   la conexión de DBus de quien la pidió y la suelta apenas ese proceso
   termina**. Un `qdbus` dura milisegundos, así que la inhibición duraba
   menos que el comando. El cookie volvía bien y aun así no pasaba nada.

Ahora lo hace `contents/code/coffee.py`, que pide tres inhibiciones
(`ScreenSaver`, `PowerManagement` y el `PolicyAgent` de PowerDevil) y se
queda vivo con la conexión abierta. Encender = lanzarlo, apagar = matarlo.
Al arrancar el widget mata cualquiera que haya quedado suelto, para que el
interruptor y la realidad coincidan.

### La grabación no arrancaba

`spectacle --record=screen`. El modo va con la **letra corta**: `s` para
pantalla, `r` para región, `w` para ventana. Con la palabra entera
Spectacle no lo reconoce y sale sin grabar.

### El video de la grabación salía corrupto

Se detenía con `pkill -INT -x spectacle`, copiado de la versión de
Hyprland, donde `wf-recorder` sí cierra el archivo al recibir SIGINT.
Spectacle no hace nada con esa señal: se muere en el acto y el mp4 queda
**sin el índice que va al final** (el "moov atom"), la tabla que dice
dónde empieza cada cuadro. El archivo tenía los datos —medio mega de
video— pero ningún reproductor lo podía abrir. `ffprobe` lo decía sin
vueltas: `moov atom not found`.

Spectacle no tiene ningún método de DBus para detener (se revisó con
`busctl introspect`: solo `RecordScreen`, `RecordRegion`, `RecordWindow`),
ni entiende SIGTERM, y `quit` por DBus tira la grabación sin guardar nada.
La forma buena —la misma que usan el punto rojo de la bandeja y repetir el
atajo de teclado— es **volver a pedirle que grabe**: el segundo pedido
apaga la grabación en curso y ahí sí cierra el archivo bien.

Dos detalles que costaron encontrar:

- **Hay que repetirle el mismo `--output`.** Sin la ruta también corta,
  pero tira la grabación: no aparece ningún archivo, ni en la carpeta
  elegida ni en la de Spectacle. Por eso `stop()` usa `root.lastFile`.
- **Va con un `pgrep -x spectacle` adelante.** Si la grabación ya se cortó
  por otro lado, el segundo pedido arrancaría una grabación nueva en vez
  de no hacer nada.

Probado punta a punta con los comandos exactos de la isla: 17 s grabados,
`ffprobe` lee duración y códec (h264 1920x1080) sin una queja.

Aparte: **arrancar la grabación falla sola de vez en cuando**. Spectacle
sale al instante, sin archivo y sin decir nada en el journal. Es cosa de
Spectacle, no de la isla —el comando es idéntico las dos veces—; volviendo
a apretar, arranca.

### La fila de FPS escribía en la nada

Quedó de la versión de Hyprland, donde `wf-recorder` sí acepta FPS.
Spectacle no, así que la propiedad se había sacado del servicio pero la
fila seguía intentando escribirla. Está oculta.

## El fondo líquido del reproductor

Detrás del reproductor se mueven tres manchas con los colores de la
carátula. Dos cosas que costaron:

- **Nada de `MultiEffect` sobre una capa.** Era la forma obvia de
  desenfocar (`layer.enabled` + blur), y **revienta el proceso** a los
  10-25 segundos con violación de segmento. Reproducible, dos de dos. Acá
  adentro eso se lleva plasmashell entero, así que ni probarlo. Cada mancha
  se dibuja como 14 círculos concéntricos con opacidad muy baja: da la
  misma difuminación sin tocar ningún shader. Con pocas capas y mucha
  opacidad se ven los aros uno por uno; con muchas y poca, se funden.
- **`Kirigami.ImageColors` no descarga direcciones de internet.** Pasándole
  la URL devuelve gris. Hay que apuntarle al `Image` que ya cargó la
  carátula (`source: artImg`), y ahí sí saca los colores.
- **Los tonos salen de `palette`, no de `highlight` ni de `average`.** Esos
  dos son colores *calculados*: `highlight` busca el más vivo y a veces
  inventa uno que en la tapa no está, y `average` es la mezcla de todos,
  o sea un barro que tampoco está. Por eso el fondo aparecía a veces con
  colores que no eran de la carátula. `paleta.palette` es el recuento real
  de la imagen ordenado por cuánto lugar ocupa cada color; se usan los tres
  primeros.
- **Círculos concéntricos apilados = líneas visibles.** La mancha eran 34
  círculos, uno adentro del otro, cada uno un poco más opaco. Cada círculo
  tiene su borde, y con cualquier carátula de color se veían: líneas
  concéntricas atravesando el fondo. Ahora cada mancha es **un degradado
  radial pintado con `Canvas`**, que no tiene escalones. Sigue sin haber
  ningún shader de por medio, que es la condición acá adentro.
- **El degradado se pinta en 220 px y se estira al tamaño real** (unos
  780). Pintar los 780 cuesta trece veces más, y al agrandar uno chico el
  suavizado de la tarjeta gráfica termina de borrar cualquier resto de
  escalón. Necesita `smooth: true`, si no Qt lo agranda a lo bruto.
- **La curva de opacidad tiene que ser ancha.** Es
  `1 - e^(-1,15·(1-t²))`, que es exactamente lo que sumaban los 34
  círculos: llena casi toda la mancha y recién sobre el borde se va a
  nada. Se probó bajarla más rápido (`(1-t)^2,4`): el color queda pegado
  al centro y la tarjeta se ve casi negra.
- **Las manchas miden 1,4 veces el ancho de la tarjeta y se mueven por su
  centro**, no por su esquina: moviendo la esquina, el centro denso queda
  siempre fuera de cuadro y solo se ve el borde desvanecido.
- **Al cambiar de canción el color salta, no se cruza.** Antes había un
  `Behavior on color` de 900 ms; con `Canvas` eso significaría repintar
  tres degradados cuadro a cuadro durante un segundo, trabajo de más
  adentro de plasmashell. La tapa cambia de golpe igual, así que no se
  nota.

## Por qué los videos no muestran miniatura

Firefox no publica `mpris:artUrl`, así que no hay imagen que mostrar. Se
comprobó leyendo el DBus del navegador: solo manda el título. Spotify sí la
manda. Para que el navegador también la publique hay que instalarle la
extensión **Plasma Integration** (el paquete `plasma-browser-integration`
ya está, falta la extensión en el navegador).

Mientras tanto, sin carátula se muestra el icono de la aplicación que está
sonando, en vez de la nota musical genérica.
