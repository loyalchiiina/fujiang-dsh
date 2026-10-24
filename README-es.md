# 富江DSH完美破甲 · Fujiang Armor

Fujiang Armor es un plugin local para DSH. Incluye reglas de prompt integradas y ofrece inyección y desinstalación con un solo clic en Windows. Cuando el plugin está cargado, aparece «富江破甲已激活» (Fujiang Armor activado) encima del cuadro de entrada.

Versión actual: `0.4.4`. Identificador del plugin: `fujiang-armor`.

## 功能 · Features

- Las reglas integradas se despliegan con el plugin; no hay que copiar prompts a mano.
- Inyección de prompt en dos capas: núcleo general en Order 100 + espejo reforzado en Order 200; una opción de configuración permite usar solo una capa.
- Inyección y desinstalación mediante archivos por lotes de doble clic.
- Detección automática del entorno; si falta Node.js, npm o pnpm, se descarga y prepara automáticamente.
- Muestra el estado de activación y el veredicto en tiempo real encima del cuadro de entrada.

## 安装前准备 · Before you install

- Use Windows, instale DSH y arránquelo al menos una vez para que se genere el directorio `%USERPROFILE%\.dsh`.
- La primera instalación requiere conexión a Internet. Si ya hay Node.js 22 o superior y npm disponibles, se reutilizan; si faltan, el instalador descarga la versión LTS oficial de Node.js, verifica el SHA256 y la coloca en el directorio del usuario, sin permisos de administrador.
- Cierre DSH por completo antes de instalar, para que el programa en ejecución no siga usando el plugin antiguo.

## 一键安装 · Install

1. Descargue el ZIP desde la página de publicaciones, o use «Code → Download ZIP» en el repositorio.
2. Descomprima el ZIP completo y abra la carpeta que contiene `点我一键注入.bat`.
3. Cierre DSH por completo.
4. Haga doble clic en `点我一键注入.bat`.
5. Si se detectan varias configuraciones de DSH, elija la de destino según las indicaciones del instalador.
6. Espere a que terminen la descarga del entorno y la instalación, y reinicie DSH.
7. Abra una conversación y confirme que aparece «富江破甲已激活» encima del cuadro de entrada. Escriba la palabra de activación «富江» para usar las reglas integradas.

El plugin se instala en `%USERPROFILE%\.dsh\plugins\fujiang-armor`. Conserve la carpeta descomprimida: los scripts de desinstalación están ahí.

El Node.js descargado se guarda en `%LOCALAPPDATA%\FujiangArmor\runtime` y se reutiliza en la siguiente instalación. El instalador solo define el entorno para el proceso actual y no modifica el PATH del sistema.

## 一键卸载 · Uninstall

1. Cierre DSH por completo.
2. En la carpeta descomprimida, haga doble clic en `点我一键卸载.bat`.
3. Si aparece un selector de configuración, elija la configuración de destino usada antes.
4. Espere a que termine la desinstalación y reinicie DSH.

## 常见问题 · FAQ

| Problema | Solución |
| --- | --- |
| No se encuentra la configuración de DSH | Instale y arranque DSH una vez, confirme que existe `%USERPROFILE%\.dsh` y vuelva a ejecutar el instalador. |
| Falló la descarga del entorno | Confirme que la red permite acceder a `nodejs.org` y al registro de npm, y vuelva a ejecutar el instalador. |
| Falló la verificación del entorno | El instalador no usa paquetes que no pasen la verificación; revise la red y reintente. |
| No se encuentran scripts, reglas u otros archivos | Descomprima el paquete completo y conserve subcarpetas como `prompts` y `scripts`. |
| Instalación correcta pero sin estado de activación | Cierre y reinicie DSH por completo y confirme que eligió la configuración en uso. |
| Tras desinstalar sigue apareciendo el estado | Cierre y reinicie DSH por completo y confirme que desinstaló la configuración correcta. |

«富江破甲已激活» indica que el plugin está cargado. La respuesta real depende del modelo elegido, de otros prompts y de la versión de DSH.

## DSH 无限重启 · Restart loop

Se revisó la página oficial de dsh-purge: la versión 1.1.52 considera el estado desalineado cuando la marca de parche aplicada no tiene `sha`, y vuelve a parchear al arrancar pidiendo reinicio; desde 1.1.53 se corrigió la marca vacía. Si usa 1.1.52 y sufre reinicios repetidos, actualice a 1.1.53 o superior.

Este plugin no contiene código que reinicie DSH. El parche de compatibilidad solo se aplica durante la instalación; al arrancar, el plugin ya no reescribe archivos del host ni del profile.
