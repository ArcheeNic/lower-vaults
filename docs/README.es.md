# Las bóvedas inferiores

[English](../README.md) · [简体中文](README.zh-CN.md) · [Русский](README.ru.md) · **Español** · [Português (Brasil)](README.pt-BR.md) · [Deutsch](README.de.md) · [日本語](README.ja.md) · [Français](README.fr.md) · [Polski](README.pl.md) · [한국어](README.ko.md)

Un paseo en primera persona por una torre sin fin. El recorrido empieza en el Archivo de pesas y medidas, sobre un puente de madera entre hileras de cajones. Las escaleras llevan al aljibe de las mareas, al observatorio y al bosque de diapasones. Cada habitante tiene un sonido propio que permite reconocerlo antes de verlo.

![Una pasarela de madera con barandillas de latón discurre entre los cajones del archivo.](screenshots/archive.jpg)

*Archivo de pesas y medidas*

## Cómo jugar

Extrae todo el archivo x86-64 de tu plataforma. Deja las bibliotecas de EOS junto al ejecutable. Al empezar una partida, la versión configurada abre una sala y muestra arriba a la derecha su código de seis caracteres, por ejemplo `K7Q-2MX`. Tus compañeros lo escriben en la pantalla de inicio y pulsan **Unirse con código** para recorrer la misma expedición.

- **Windows** — haz doble clic en `LowerVaults.exe`.
- **Linux** — ejecuta estos comandos en la carpeta extraída.

```sh
chmod +x LowerVaults.x86_64
./LowerVaults.x86_64
```

### Si Windows bloquea el juego

La versión para Windows todavía no está firmada, así que Windows puede impedir que se abra.

- **Microsoft Defender SmartScreen** muestra «Windows protegió su PC». Pulsa **Más información** y luego **Ejecutar de todas formas**.
- El **Control inteligente de aplicaciones** (Smart App Control) bloquea los programas sin firma y no permite abrirlos. Puedes desactivarlo en **Seguridad de Windows → Control de aplicaciones y navegador → Configuración de Control inteligente de aplicaciones**. En algunas versiones de Windows 11 solo se puede volver a activar reinstalando Windows. La versión para Linux no tiene esta restricción.

Solicitamos a SignPath Foundation un certificado gratuito de firma de código. La fundación solo certifica proyectos que ya son conocidos, así que por ahora rechazó la solicitud. Volveremos a pedirlo cuando el juego sea más conocido.

## Controles

| Acción | Control |
| --- | --- |
| Entrar en la torre | Intro, barra espaciadora o el botón **Entrar** |
| Caminar | WASD o las flechas |
| Mirar alrededor | Ratón |
| Correr | Mantén pulsada Mayús al moverte |
| Pausar o continuar | Esc |
| Salir | Esc → **Salir del juego** |

En el menú de pausa puedes ajustar la sensibilidad del ratón, el volumen general y el volumen de tus pasos por separado.

## Idioma

El selector de idioma está en la esquina superior derecha de la pantalla de inicio y del menú de pausa. Los menús, las indicaciones y los nombres de los lugares cambian al instante. Al iniciarse por primera vez, el juego usa el idioma del sistema si está disponible y, en caso contrario, el inglés. El idioma elegido se guarda para la próxima partida. Al principio de esta página encontrarás enlaces a los diez idiomas.

## Capturas de pantalla

![Un camino de piedra pasa bajo arcos apuntados y conduce a un rosetón.](screenshots/cathedral.jpg)

*Catedral sobre el abismo*

![El cráneo y las costillas de un leviatán se alzan sobre una red de puentes estrechos.](screenshots/leviathan.jpg)

*Restos del leviatán*

## Registro de cambios

Los cambios de cada versión están en el [registro de cambios](CHANGELOG.es.md).

## Licencia

El código y los recursos del juego se publican con la [Apache License 2.0](../LICENSE). La fuente de respaldo para chino, japonés y coreano usa la [SIL Open Font License](../i18n/fonts/OFL.txt). Los archivos de cada versión incluyen además el SDK de Epic Online Services, que Epic distribuye con sus propias condiciones.

## Privacidad

Al empezar un paseo, el juego se conecta a Epic Online Services para encontrar compañeros por código de sala. Inicia sesión con un identificador de dispositivo anónimo y solo comparte tu posición y orientación con los jugadores de la misma sala. El juego no envía ningún otro dato. Epic gestiona la conexión según su [política de privacidad](https://www.epicgames.com/site/privacypolicy).

## Consumo de tokens de la versión 0.1.0

| Herramienta | Sesiones | Tokens |
|---|---|---:|
| Codex | 4 principales y 6 de subagentes | 75 875 836 |
| Claude Code | 1 de preparación del lanzamiento | 1 645 162 |
| **Total** | **11** | **77 520 998** |

Según los registros locales de desarrollo y preparación del lanzamiento del 24 y 25 de noviembre de 2026, el 98,45 % de los tokens se leyó de la caché. De los 1 199 332 restantes, los modelos generaron 364 313.

## Compilar desde el código fuente

Utiliza **Godot 4.7.1 stable** y las plantillas de exportación de la misma versión. Puedes instalarlas desde **Editor → Manage Export Templates**. Para jugar desde el editor, abre `project.godot` y pulsa F5.

Ejecuta los siguientes comandos desde la raíz del proyecto para generar ambas versiones. El comando `godot` debe abrir el ejecutable del editor.

```sh
python3 tools/install_eos.py
godot --headless --import
godot --headless --export-release "Linux"
godot --headless --export-release "Windows"
```

Las rutas de salida se definen en [export_presets.cfg](../export_presets.cfg). Los textos originales están en ruso y las otras nueve traducciones en [i18n](../i18n/). El juego incluye una fuente de reserva para chino, japonés y coreano. [Licencia de la fuente](../i18n/fonts/OFL.txt).
