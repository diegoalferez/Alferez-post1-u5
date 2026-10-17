# Alferez-post1-u5 — Emuladores y Virtualización

Arquitectura de Computadores · Unidad 5 · Post-contenido · UFPS

**Estudiante:** Diego Alferez

Este repositorio único documenta el laboratorio guiado de la Unidad 5, dividido en dos partes: la Parte 1 trabaja con **DOSBox** (emulación de hardware x86 de 16 bits y programas en ensamblador con NASM) y la Parte 2 con **VirtualBox** (virtualización de un sistema operativo completo, Alpine Linux). El documento se mantiene como bitácora técnica y está redactado en tercera persona.

## 1. Entorno de trabajo

| Componente | Detalle |
|---|---|
| Sistema anfitrión | Windows 11 |
| DOSBox | 0.74-3 |
| NASM para DOS | 2.15.05 (compilado el 28 de agosto de 2020) |
| VirtualBox | [AJUSTAR: versión 7.x] |
| SO huésped | Alpine Linux 3.19.x (Standard, x86_64) |
| VM `Lab5-Alpine` | 1 GB de RAM y 1 CPU al crearse; 2 GB y 2 CPUs tras el Paso 5; disco VDI dinámico de 10 GB; segundo disco VDI fijo de 4 GB |

## 2. Estructura del repositorio

```
Alferez-post1-u5/
├── README.md
├── dosbox.conf                 (Parte 1)
├── src/                        (Parte 1) saludo.asm, entrada.asm, ciclos.asm
├── bin/                        (Parte 1) saludo.com, entrada.com, ciclos.com
├── VBoxManage_commands.sh      (Parte 2)
└── capturas/                   capturas de ambas partes
```

Los archivos `.ova` y el disco fijo `Lab5-Alpine-fixed.vdi` no se suben al repositorio por su tamaño (ver `.gitignore`); se documentan con capturas.

---

## 3. Parte 1 — DOSBox y ensamblador

El estudiante creó el directorio de trabajo, inicializó Git en la rama `main` y configuró `dosbox.conf` para montar la carpeta del proyecto como unidad `C:`. Todos los comandos de ensamblado se ejecutan desde la raíz `C:\`, por ejemplo `nasm -f bin src\saludo.asm -o bin\saludo.com`.

**Checkpoint 1 — estructura:** ![cp1](capturas/p1_cp1_estructura.png)

**Checkpoint 2 — DOSBox con NASM:** ![cp2](capturas/p1_cp2_dosbox_nasm.png)

**Checkpoint 3 — `saludo.com` (INT 21h función 09h):** ![cp3](capturas/p1_cp3_saludo.png)

**Checkpoint 4 — `entrada.com` (INT 21h funciones 07h, 02h y 09h):** ![cp4](capturas/p1_cp4_entrada.png)

**Checkpoint 5 — sesión con DEBUG sobre `saludo.com`** (`-r`, `-u`, `-t`, `-p` y `-g`): ![cp5](capturas/p1_cp5_debug.png)
![cp5 pasos](capturas/p1_cp5_debug_pasos.png)

**Checkpoint 6 — `ciclos.com` con `cycles=8000`** (INT 21h función 2Ch): ![cp6](capturas/p1_cp6_ciclos_8000.png)

### Comparación del valor de `cycles` (Checkpoint 7)

El número de iteraciones es idéntico en las tres corridas (300 × 65535); solo cambia `cycles` en `dosbox.conf`.

| Corrida | cycles | Hora inicial (hh:mm:ss:cc) | Hora final (hh:mm:ss:cc) | Duración observada (centésimas) |
|---|---|---|---|---|
| 1 | 8000 | 20:49:01:27 | 20:49:06:21 | 494 |
| 2 | 1000 | 20:53:56:61 | 20:54:35:99 | 3938 |
| 3 | 20000 | 20:59:10:67 | 20:59:12:65 | 198 |

En la corrida 2 el minuto cambió de 53 a 54 durante la medición, por lo que se sumaron 6000 centésimas a la hora final para calcular la duración. Las duraciones son inversamente proporcionales a cycles: con cycles=1000 (3938 centésimas) el bucle tarda unas 8 veces lo que tarda con cycles=8000 (494), y con cycles=20000 (198) tarda unas 2,5 veces menos, la misma relación que hay entre los valores de cycles. Esto confirma que cycles controla la velocidad de emulación y no la corrección del programa, que ejecuta exactamente las mismas iteraciones en las tres corridas.

![cycles 1000](capturas/p1_cp7_cycles_1000.png)
![cycles 20000](capturas/p1_cp7_cycles_20000.png)

### Decisión técnica 1 — ¿qué valor de `cycles` es el correcto para este laboratorio?

El valor correcto para este laboratorio es uno fijo, `cycles=8000`. Con `cycles=max`, DOSBox emula tantas instrucciones por segundo como el procesador anfitrión permita, que en un equipo moderno son decenas o cientos de millones; el bucle de `ciclos.com`, cuyo tamaño es fijo en el código fuente, terminaría en una fracción del tiempo que tarda con 8000 y la diferencia entre la hora inicial y la final se acercaría a cero centésimas. Como la duración dependería de la potencia del equipo y no del programa, la medición quedaría invalidada: el bucle es solo un mecanismo de espera, el mismo recurso que usaron muchos programas y juegos de la era DOS. Con `cycles=auto` ocurre algo parecido, porque DOSBox ajusta el valor dinámicamente y el resultado cambia entre equipos y ejecuciones. Un valor fijo desacopla la velocidad de emulación del hardware real y obliga a cualquier equipo a emular aproximadamente la misma cantidad de instrucciones por unidad de tiempo, de modo que las mediciones de distintos estudiantes sean comparables y reproducibles. Fuera de este laboratorio, `cycles=max` o `cycles=auto` son la opción correcta al ejecutar software de productividad moderno escrito para DOS (compiladores, editores o programas pesados en modo protegido), donde no hay temporización atada al reloj del procesador y se busca la mayor velocidad posible.

### Decisión técnica 2 — tiempo emulado en DOSBox frente a los ciclos de CPU reales

El valor `cycles` de `dosbox.conf` y la frecuencia del procesador anfitrión no son comparables: `cycles` indica cuántas instrucciones x86 de 16 bits intenta emular DOSBox por milisegundo de tiempo virtual, mientras que los gigahercios del anfitrión indican ciclos de reloj físicos del silicio. Compararlos es un error de categoría, como comparar páginas por minuto con kilómetros por hora. Cada instrucción emulada exige que DOSBox la interprete por software: la decodifica, actualiza registros, banderas y memoria virtual, y para ello ejecuta decenas o cientos de instrucciones nativas del anfitrión. Por eso el proceso `DOSBox.exe` consume muchos más ciclos reales por segundo de los que sugiere `cycles`, y su uso de CPU no puede deducirse leyendo el archivo de configuración. Para estimar cuántos ciclos reales consume la ejecución de `ciclos.com`, se debe medir en el sistema anfitrión con una herramienta de monitoreo de procesos: el Administrador de tareas o el Monitor de recursos para el porcentaje de CPU, y Process Explorer (columna *Cycles Delta*) o un perfilador como `perf stat` en Linux para contar los ciclos reales del proceso.

**Checkpoint 8 — decisiones técnicas de `cycles`:** ![cp8](capturas/p1_cp8_decisiones.png)

---

## 4. Parte 2 — VirtualBox y Alpine Linux

El estudiante creó la VM `Lab5-Alpine` con `VBoxManage` (comandos completos en `VBoxManage_commands.sh`), instaló Alpine Linux con `setup-alpine`, probó los modos de red, gestionó snapshots, reasignó recursos, comparó discos y exportó la VM.

**Checkpoint 1 — VM configurada:** ![cp1](capturas/p2_cp1_vm_config.png)

**Checkpoint 2 — Alpine instalado, IP y ping por NAT:** ![cp2](capturas/p2_cp2_alpine_ip_ping.png)

### Modos de red (Checkpoint 3)

| Modo | IP obtenida en `eth0` | `ping 8.8.8.8` desde la VM | Observación |
|---|---|---|---|
| NAT | [REGISTRAR] | [responde / no responde] | [REGISTRAR] |
| Host-Only | [REGISTRAR] | [responde / no responde] | Ping del anfitrión a la VM: [responde / no responde] |
| Bridge | [REGISTRAR] | [responde / no responde] | [REGISTRAR] |

![NAT](capturas/p2_cp3_red_nat.png)
![Host-Only](capturas/p2_cp3_red_hostonly.png)
![Bridge](capturas/p2_cp3_red_bridge.png)

### Snapshots (Checkpoint 4)

Árbol de snapshots (salida de `VBoxManage snapshot "Lab5-Alpine" list`):

```
[PEGAR AQUÍ LA SALIDA DEL COMANDO]
```

![lista de snapshots](capturas/p2_cp4_snapshots_lista.png)
![curl ausente tras restaurar](capturas/p2_cp4_curl_ausente.png)

### Recursos (Checkpoint 5)

Con `VBoxManage modifyvm "Lab5-Alpine" --cpus 2 --memory 2048` y la VM apagada, `nproc` y `free -m` dentro de Alpine confirman la nueva asignación.

![nproc y free](capturas/p2_cp5_nproc_free.png)

### Disco fijo frente a dinámico (Checkpoint 6)

| Tipo de disco | Comando | Tiempo real (campo `real` de `time`) |
|---|---|---|
| Fijo (`Lab5-Alpine-fixed.vdi`) | `dd` de 200 MB sobre `/mnt/fijo/test.img` | [REGISTRAR] |
| Dinámico (`Lab5-Alpine.vdi`) | `dd` de 200 MB sobre `/root/test.img` | [REGISTRAR] |

![benchmark](capturas/p2_cp6_dd.png)

### Decisión técnica 3 — modo de red y seguridad

Para una VM de práctica que el estudiante ejecuta en su propio equipo, NAT es el modo más apropiado por defecto. En NAT, VirtualBox coloca la VM detrás de un enrutador virtual (IP típica 10.0.2.15): la VM puede iniciar conexiones hacia internet, pero ningún dispositivo de la red local puede iniciarlas hacia ella salvo que se configure un reenvío de puertos, de modo que queda aislada de la red del estudiante. Host-Only sería preferible en un ejercicio de Arquitectura de Computadores donde se quiera experimentar con direcciones, servicios o configuraciones de red sin que la VM genere ni reciba tráfico externo, ni siquiera saliente; a cambio, se pierde el acceso a internet, así que no funcionan `apk update` ni las descargas de paquetes. Bridge es la opción de mayor riesgo para este escenario: la VM recibe una IP en la misma red local que el anfitrión y queda alcanzable por cualquier otro dispositivo de esa red, incluidos los servicios que Alpine tenga activos, como `sshd` con una contraseña de root de laboratorio. Esto amplía la superficie de ataque y facilita accesos no autorizados.

### Decisión técnica 4 — disco fijo frente a dinámico y asignación de CPU/RAM

En la medición del estudiante, el disco [FIJO / DINÁMICO] resultó más rápido en escritura secuencial ([X] s frente a [Y] s). Un disco fijo reserva todo su tamaño en el anfitrión al crearse, por lo que el archivo `.vdi` ya existe completo y cada escritura del huésped cae en espacio ya asignado; un disco dinámico debe hacer crecer el archivo `.vdi` en el sistema de archivos del anfitrión y actualizar su mapa de bloques cuando el huésped escribe en bloques aún no asignados, lo que añade un costo. Aun así, el disco dinámico es la opción por defecto en un laboratorio con muchos estudiantes y equipos de capacidad limitada, porque solo ocupa el espacio realmente usado (Alpine usa una fracción de sus 10 GB), mientras que el disco fijo ocupa de inmediato todos sus 4 GB. Asignar 2 CPUs y 2048 MB de RAM es razonable en un anfitrión de 4 a 8 CPUs y 8 a 16 GB: Alpine necesita muy poco y el anfitrión conserva recursos para su propio sistema operativo. Asignar todos los CPUs o la mayor parte de la RAM dejaría al anfitrión sin recursos y provocaría lentitud, uso intensivo del disco como memoria e inestabilidad.

**Checkpoint 7 — decisiones técnicas de red y almacenamiento:** ![cp7](capturas/p2_cp7_decisiones.png)

### Exportación OVA (Checkpoint 8)

La VM se exportó con `VBoxManage export "Lab5-Alpine" --output "Lab5-Alpine-export.ova" --manifest`. El archivo no se sube al repositorio. [AGREGAR enlace si se aloja en un servicio externo.]

![ova](capturas/p2_cp8_ova.png)
![repositorio en GitHub](capturas/p2_cp8_github.png)

---

## 5. Conclusiones

La emulación (DOSBox) recrea por software el hardware x86 de 16 bits y el entorno DOS; cada instrucción se interpreta, por lo que el rendimiento queda gobernado por el valor `cycles` y no por el procesador real. La virtualización (VirtualBox) ejecuta el sistema huésped sobre hardware real o casi real mediante un hipervisor, con un costo mucho menor por instrucción. En el laboratorio, `cycles` demostró controlar la velocidad de emulación y no la corrección del programa: el mismo `ciclos.com` tardó más con `cycles=1000` y menos con `cycles=20000`. En la Parte 2, NAT resultó el modo más seguro por defecto, Host-Only sirvió para aislar la VM por completo y Bridge fue el de mayor exposición. Los snapshots permitieron revertir la instalación de software sin repetirla, y la comparación de discos mostró el equilibrio entre rendimiento (disco fijo) y espacio ocupado (disco dinámico). [AJUSTAR con las observaciones propias del laboratorio.]
