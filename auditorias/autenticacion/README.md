# Auditoría — Autenticación (huella, keyring, SDDM, Quickshell lockscreen)

**Fecha:** 2026-08-04
**Alcance:** stack de autenticación (PAM, fprintd, gnome-keyring, SDDM, lockscreen de Quickshell) en la máquina actual.
**Estado:** **bug del keyring en SDDM resuelto y confirmado en vivo** (ver §9). Pendiente: reconstruir huella en el lockscreen de Quickshell (§7.2, todavía no arrancado) y reconocimiento facial para el lockscreen (nuevo, sin explorar).

---

## 0. TL;DR de cómo quedó resuelto (ver §9 para el detalle completo)

Después de dos intentos fallidos (puente de credencial cacheada vía TPM2, y un módulo PAM en Rust inyectando `PAM_AUTHTOK`), la solución que **sí funciona**, confirmada con `journalctl` en logins reales: en `/etc/pam.d/sddm`, la fase `auth` dejó de usar `include system-login` y pasó a ser autocontenida, cambiando únicamente `pam_fprintd.so` de `sufficient` a `optional`. Con `pam_unix.so` como `required` justo después, **la contraseña se verifica siempre, sin excepción** — la huella nunca decide el login por sí sola (ya no hay atajo que se salte la contraseña), pero tampoco bloquea nada si no la usás (cae a pedir contraseña sola, timeout de 4s). Como la contraseña corre siempre, `pam_gnome_keyring.so` (sin modificar) se desbloquea con su mecanismo normal en el 100% de los logins. `system-auth` (sudo, TTY) queda intacto — sigue siendo huella-o-contraseña ahí.

---

## 1. Resumen ejecutivo

- El bug del keyring que reportaste está **confirmado y reproducido con evidencia de `journalctl` real** (no es una suposición). Causa raíz identificada con precisión: `pam_fprintd.so` está como `sufficient` en `/etc/pam.d/system-auth`, *antes* de `pam_unix.so`. Cuando la huella funciona a la primera, PAM corta la cadena ahí mismo y `pam_unix.so` nunca corre — así que `pam_gnome_keyring.so` nunca recibe la contraseña que necesita para descifrar `login.keyring`, y queda bloqueado toda la sesión.
- **Hallazgo no buscado, pero importante**: el lockscreen de Quickshell (`modules/lock/LockAuth.qml`) **no tiene soporte de huella en absoluto** hoy — solo un `PamContext` de contraseña. Esto contradice memoria de sesiones anteriores (2026-07-28) que decía que un dual-PamContext (huella + contraseña en paralelo) estaba implementado y "confirmado funcionando en vivo". El código actual no lo tiene. Ver §4.
- Un commit de **hoy mismo** (`a96c0bd`, "feat(system): add fingerprint-only PAM service for lockscreen") agregó `system/pam.d/quickshell-fprint` — un PAM service correctamente diseñado para huella-only — pero **nada en el proyecto lo usa**. Es configuración muerta a la espera de que `LockAuth.qml` la conecte. Ver §5.
- `bootstrap.sh` no reproduce nada de esto: no instala `fprintd`, no inserta `pam_fprintd.so` en `system-auth`, y no despliega `system/pam.d/quickshell-fprint`. El propio `CLAUDE.md` tampoco documenta un "paso 33 — huella" pese a que la memoria dice que se agregó tres veces. Si reinstalás desde cero hoy, la huella no queda funcionando. Ver §6.

---

## 2. Qué SÍ funciona hoy

- **SDDM (pantalla de login)**: `pam_fprintd.so` corre transparentemente porque `sddm` → `system-login` → `system-auth`, y ahí vive la línea `sufficient`. No hace falta tocar el tema QML de SDDM para esto — es 100% invisible a nivel PAM. Confirmado en vivo por logs (`"Place your right index finger on the fingerprint reader"` en cada login).
- **gnome-keyring está instalado y corriendo** (`gnome-keyring-daemon.service` activo, socket-activated). `~/.local/share/keyrings/login.keyring` existe y es del tamaño esperado.
- **`/etc/pam.d/sddm` ya tiene el wiring estándar de keyring** (`pam_gnome_keyring.so` en auth/password/session) — esto no lo agregaste vos, viene del paquete `sddm`/pambase por defecto, y es correcto.

## 3. El bug del keyring — diagnóstico con evidencia

`/etc/pam.d/system-auth` (fragmento relevante, orden real):
```
auth       sufficient                  pam_fprintd.so timeout=4
auth       required                    pam_faillock.so      preauth
-auth      [success=2 default=ignore]  pam_systemd_home.so
auth       [success=1 default=bad]     pam_unix.so          try_first_pass nullok
```

`sufficient` significa: si `pam_fprintd.so` da éxito, PAM deja de evaluar el resto del stack `auth` — `pam_unix.so` **se salta por completo**. Sin `pam_unix.so`, no hay `PAM_AUTHTOK` (la contraseña en texto plano) disponible para que `pam_gnome_keyring.so` (en `/etc/pam.d/sddm`) descifre `login.keyring`.

Se revisaron 15 boots recientes (`journalctl --list-boots`, del 31 de julio al 4 de agosto) y aparecen dos patrones perfectamente consistentes:

**Patrón A — la huella falla/tarda, cae a contraseña (funciona bien):**
```
sddm[...]: "Place your right index finger on the fingerprint reader"
sddm[...]: "Verification timed out"
sddm-helper[...]: gkr-pam: stashed password to try later in open session
sddm[...]: Authentication for user "deadlock" successful
sddm-helper[...]: gkr-pam: unlocked login keyring
```

**Patrón B — la huella funciona a la primera (keyring queda bloqueado — el bug):**
```
sddm[...]: "Place your right index finger on the fingerprint reader"
sddm[...]: Authentication for user "deadlock" successful
sddm-helper[...]: gkr-pam: couldn't unlock the login keyring.
```

De los 15 boots muestreados, **7 mostraron el Patrón B**. En esos casos, Chromium, `git-credential-libsecret`, las contraseñas guardadas de Wi-Fi (NetworkManager/iwd si las usara vía Secret Service) y cualquier otro consumidor de libsecret quedan sin acceso al keyring hasta que algo lo desbloquee manualmente esa sesión.

Este es un problema conocido y documentado en la interacción `fprintd` + `gnome-keyring` en cualquier distro que apile los dos así — no es una particularidad de tu config, pero sí está pasando exactamente así en esta máquina.

---

## 4. Discrepancia con memoria: huella en el lockscreen de Quickshell

Sesiones del 2026-07-28 (memoria del proyecto) registran:
> "Implementado dual-PamContext (pam = 'passwd', pamFingerprint = 'quickshell-fprint') en LockAuth.qml — huella o contraseña desbloquean independientemente. **Usuario confirmó funcionando en vivo.**"

El código actual de `LockAuth.qml` (leído completo, línea por línea) contiene **un solo `PamContext`**, `config: "passwd"`. No hay segundo contexto, no hay import ni referencia a huella, no hay indicador de estado de huella. `grep` de `"quickshell-fprint"` en todo el repo solo encuentra el propio archivo PAM.

Además, `docs/roadmap.md` del proyecto Quickshell lista "avatar + password/**fingerprint**" como completo (fases 0-6), y `lockscreen.md` documenta el patrón de dos `PamContext` — pero ese mismo archivo aclara que es la arquitectura de referencia de **Caelestia** (proyecto externo), y que "el lockscreen actual no sigue esa arquitectura tal cual". La documentación del propio proyecto ya reconoce la divergencia.

**Conclusión**: el trabajo de huella en el lockscreen se perdió — coincide con el patrón de "persistence-loss" ya detectado antes en este mismo proyecto (ediciones que una sesión reportó como "ya aplicadas" pero nunca se escribieron a disco). El commit de hoy (`a96c0bd`) parece ser un primer paso de reconstrucción — el PAM service — pero sin el lado QML todavía.

---

## 5. `system/pam.d/quickshell-fprint` — configuración muerta

Contenido (mirror exacto entre repo y `/etc/pam.d/quickshell-fprint`):
```
#%PAM-1.0
auth       required     pam_fprintd.so max-tries=1
account    required     pam_permit.so
```

Bien diseñado para lo que pretende: sin `pam_unix`, sin timeout artificial, `max-tries=1` para que un mal swipe no bloquee 3 intentos antes de completar (evita el bug de recuperación lenta ya documentado). Pero **nada en `LockAuth.qml` abre un `PamContext { config: "quickshell-fprint" }`** — es un archivo huérfano hoy.

---

## 6. Gap de reproducibilidad

`grep -in "fprintd\|fingerprint" dotfiles/bootstrap.sh` → **sin resultados**. Ni instala `fprintd`/`libfprint`, ni inserta la línea en `system-auth`, ni despliega `system/pam.d/quickshell-fprint`. `CLAUDE.md` tampoco documenta ese paso (salta de "Boot optimization" a "Cybersecurity" sin mención de huella). Una reinstalación desde cero con `install.sh` hoy **no reproduce nada de la huella** — quedaría todo por rehacer a mano.

---

## 7. Propuestas de mejora

### 7.1 — Fix del bug del keyring (elegir uno) — ⚠️ HISTÓRICO, NO ES LO QUE SE IMPLEMENTÓ

> Todo `§7.1` (incluyendo `§7.1.1`, `§7.1.2`, `§7.1.3`) documenta el camino que se **exploró y abandonó** — el puente de credencial cacheada vía TPM2. Se llegó a implementar y desplegar, pero se descubrió en vivo que no funcionaba (ver §9.1 para el porqué exacto). Se deja todo el contenido original sin borrar como registro de lo investigado — el porqué de cada decisión técnica ahí adentro sigue siendo válido y reutilizable — pero **la solución real implementada es la de §9**, mucho más simple.

### 7.1 — Fix del bug del keyring (elegir uno)

**Opción recomendada — separar "login inicial" de "desbloqueo de pantalla":**
Sacar `pam_fprintd.so` de `system-auth` (así SDDM/sudo/su vuelven a pedir siempre contraseña real, y el keyring se desbloquea normalmente cada vez). Usar huella **solo** en el lockscreen de Quickshell, vía el `quickshell-fprint` ya creado — ahí la sesión ya está corriendo y el keyring ya fue desbloqueado al hacer login, así que autenticar con huella para *volver a entrar* no necesita tocar el keyring para nada. Es la separación de responsabilidades correcta: contraseña para arrancar sesión (keyring), huella para reingresar a una sesión que ya está viva. También resuelve de paso que hoy el tema SDDM no tiene UI de huella (no se pierde nada visualmente al sacarlo de ahí).

**Opción alternativa — keyring sin contraseña ("Unlock automatically"):**
Cambiar la contraseña del `login.keyring` a vacía (vía `seahorse`/`secret-tool`) para que se desbloquee solo al iniciar el daemon, sin depender de `PAM_AUTHTOK`. Mantiene huella funcionando en SDDM tal cual está. Trade-off real: el keyring deja de estar cifrado con tu contraseña de login — en esta máquina probablemente el disco ya está cifrado por FDE, así que el riesgo incremental es bajo, pero es una decisión de seguridad que te corresponde tomar a vos, no algo que voy a asumir.

**Opción avanzada — puente de credencial cacheada (investigada a fondo el 2026-08-04, ver §7.1.1):**
Sella la contraseña real con el TPM y la libera automáticamente después de que la huella tenga éxito, para desbloquear el keyring sin escribirla nunca a mano. A diferencia de la opción recomendada, esta **no requiere sacar `pam_fprintd` de ningún lado** — huella sigue funcionando en SDDM/sudo/lockscreen tal cual está, y además el keyring queda resuelto ahí también. Es la opción elegida para implementar (ver diseño concreto abajo).

#### 7.1.1 — Diseño investigado del puente de credencial cacheada

**Por qué NO se puede "derivar" la contraseña de la huella** (confirmado, no es una limitación de esta implementación sino física): una contraseña pasa por una función de derivación de clave (KDF) y siempre produce la misma clave. Un escaneo de huella **nunca es bit-a-bit idéntico** entre lecturas (varía por ángulo, presión, ruido del sensor) — `libfprint`/`fprintd` hacen *matching* difuso contra una plantilla, no comparación exacta. No existe combinación de PAM que derive tu contraseña real desde un escaneo. Lo único posible es usar el éxito de la huella como **llave que libera** un secreto guardado aparte — nunca como el secreto en sí. Confirmado además por el propio bug tracker de GNOME (`bugzilla.gnome.org` #579843): el mantenedor de gnome-keyring lo describió como "a really tough problem" y quedó sin resolver — no hay solución nativa upstream.

**Camino técnico verificado** (evité asumir nada — cada pieza se confirmó por separado):
1. `pam_exec.so` **no sirve** para inyectar la contraseña de vuelta al stack de PAM: su `expose_authtok` es de una sola vía (PAM → script, por stdin), nunca al revés — confirmado en la página de manual de `pam_exec(8)`. Esto descarta intentar que `pam_unix.so`/`pam_gnome_keyring.so` "vean" el secreto cacheado como si fuera el `PAM_AUTHTOK` real vía un script simple.
2. Existe una vía real para eso (`pam_python`, permite `pamh.authtok = valor` → llama a `pam_set_item(PAM_AUTHTOK, ...)`, usado así en proyectos como privacyIDEA/LinOTP) — pero es más pesada (dependencia adicional, su paquete en AUR mostró señales de build inestable) y **no hace falta**, porque:
3. `gnome-keyring-daemon` tiene un modo dedicado exactamente para esto: `gnome-keyring-daemon --unlock` lee una contraseña por stdin y desbloquea (o crea) el keyring "login" directamente — sin pasar por PAM en absoluto. Confirmado en su manual. Esto es más simple que pelear con la inyección de `PAM_AUTHTOK`.
4. Ya existe un proyecto que implementa este patrón exacto de punta a punta: [`umglurf/gnome-keyring-unlock`](https://github.com/umglurf/gnome-keyring-unlock). Sella la contraseña con **Clevis + TPM2** (`clevis-encrypt-tpm2`) en un archivo, la desencripta en el arranque de sesión, y la pasa por stdin a un helper que la entrega a `gnome-keyring-daemon`. Ese proyecto la dispara desde el perfil de shell (`~/.zprofile`); en este sistema el punto de enganche más limpio es un paso de `session` en PAM (`pam_exec.so`, agregado después de la línea existente `-session optional pam_gnome_keyring.so auto_start` en `/etc/pam.d/sddm`), porque corre una vez por login real en vez de en cada shell interactivo.

**Corrección 2026-08-04 — sin política de PCR (no PCR7):** el proyecto de referencia ata el sellado a PCR7 (estado de Secure Boot). Confirmado que PCR7 registra si Secure Boot está activo, qué certificado firmó el bootloader y las revocaciones habilitadas. **Esta máquina tiene Secure Boot deshabilitado a propósito** (multi-boot con Debian/Fedora/Arch/openSUSE, evita tener que firmar/enrolar MOK en 4 distros distintos) — sin Secure Boot activo, PCR7 no verifica ninguna firma, solo registra "estaba apagado", un valor genérico y predecible que las 4 distros del mismo TPM físico probablemente alcanzan por igual. Atar el sellado a PCR7 acá daría una falsa sensación de aislamiento entre distros que no es real. **Reactivar Secure Boot solo para esto no se recomienda** — el costo (firmar/enrolar cada uno de los 4 sistemas) es desproporcionado al problema que resuelve.

**Decisión de diseño**: sellar **solo contra el chip TPM, sin política de PCR** — `clevis encrypt tpm2 '{}'` (confirmado: sin `pcr_ids` no se aplica ninguna política de PCR, el secreto queda atado únicamente a que sea *este* TPM físico el que lo desencripta). Protege lo que realmente importa (robo del disco / lectura en otro equipo) sin depender de Secure Boot. Trade-off aceptado: cualquier SO arrancado en esta misma laptop (cualquiera de las 4 distros, o un live USB) podría en teoría pedirle al TPM que libere el mismo secreto — pero ya son sistemas en los que confiás al tenerlos instalados en el mismo disco, así que no cambia el modelo de confianza real.

**Piezas necesarias para implementar** (aún sin tocar nada):
- Paquete `clevis` + `tpm2-tools` (Arch, repos oficiales/extra).
- Sellar la contraseña una vez a mano: `clevis encrypt tpm2 '{}' <<< "$password" > ruta-segura` (permisos root-only).
- Script pequeño que desencripta con `clevis decrypt` y hace `echo -n "$password" | gnome-keyring-daemon --unlock`.
- Paso `session optional pam_exec.so /ruta/al/script` en `/etc/pam.d/sddm`, después de la línea de `pam_gnome_keyring.so auto_start`.
- **A confirmar en vivo antes de darlo por cerrado** (no asumido): que llamar `--unlock` de nuevo cuando el keyring ya se desbloqueó por la vía normal (login con contraseña) sea inofensivo/idempotente.
- Trade-off de seguridad real: ahora existe en disco una copia de tu contraseña real, sellada por TPM y solo liberable en este chip físico — para alguien que ya tiene la laptop encendida (cualquiera de tus 4 SO arrancado), el riesgo incremental es bajo, pero es una superficie nueva que no existía antes.

#### 7.1.2 — Plan de implementación (pendiente de ejecutar, nada aplicado todavía)

1. **Instalar dependencias**: `sudo pacman -S clevis tpm2-tools`.
2. **Confirmar acceso al TPM**: verificar que `/dev/tpmrm0` existe y que el usuario/servicio que va a sellar tiene permisos (grupo `tss`, ya usado por `tpm2-tools`).
3. **Sellar la contraseña de login** (a mano, una sola vez, nunca scripteado — igual que el enrolamiento de huella): `clevis encrypt tpm2 '{}' <<< "TU_CONTRASEÑA_REAL" | sudo tee /etc/gnome-keyring-tpm2.jwe > /dev/null` seguido de `sudo chmod 600 /etc/gnome-keyring-tpm2.jwe` (root-only, ninguna app de usuario debe poder leerlo).
4. **Crear el script bridge** `system/scripts/unlock-keyring-tpm2.sh` (nuevo, en el repo, desplegado a `/usr/local/bin/` por bootstrap.sh) — decodifica con `clevis decrypt` y hace `echo -n "$pass" | gnome-keyring-daemon --unlock`, corriendo como el usuario real (no root) para que el daemon que desbloquea sea el de la sesión.
5. **Agregar el paso de PAM** en `system/pam.d/` — evaluar si conviene un archivo nuevo tipo `system/pam.d/sddm` (mirror del `/etc/pam.d/sddm` actual + la línea `session optional pam_exec.so /usr/local/bin/unlock-keyring-tpm2.sh` agregada después de `pam_gnome_keyring.so auto_start`) para que quede versionado, en vez de editar solo en vivo.
6. **Probar en 3 escenarios reales** antes de dar por cerrado: (a) login con huella exitosa a la primera → confirmar `journalctl` ya no muestra `couldn't unlock the login keyring`; (b) login normal con contraseña (huella falla/timeout) → confirmar que el paso nuevo no rompe nada ni duplica prompts; (c) reinicio completo, confirmar que el bridge sigue funcionando después de un `pacman -Syu` (kernel nuevo) — con sellado sin PCR esto no debería verse afectado, pero se verifica igual.
7. **Reproducibilidad**: agregar el paso a `bootstrap.sh` (instala `clevis`+`tpm2-tools`, despliega el script y el PAM service) — el sellado del paso 3 queda como paso manual post-bootstrap (como el enrolamiento de huella), documentado en `CLAUDE.md`.
8. Una vez confirmado en vivo, retomar **§7.2** (reconstruir huella en el lockscreen de Quickshell) y **§7.5** ya cubierto por el punto 7 de acá.

### 7.1.3 — Secure Boot: diferido, no descartado

Decisión 2026-08-04: se evaluó activar Secure Boot ahora (daría sellado real por PCR7 en vez de solo TPM) pero se **difiere a propósito**. Motivo del usuario: Debian/Fedora/openSUSE están instaladas solo por un curso y van a durar unos meses — no tiene sentido invertir en firmar/verificar Secure Boot en 4 distros que van a desaparecer pronto. Además, agosto 2026 es mal momento: el certificado Microsoft UEFI CA 2011 que firma el shim de la mayoría de las distros venció el 27/06/2026 y está en transición al nuevo (2023) — activar Secure Boot ahora exigiría verificar distro por distro que cada shim ya esté al día, trabajo que se tiraría cuando esas distros se borren.

**Plan a futuro** (cuando las otras 3 distros ya no hagan falta, quede solo Arch): activar Secure Boot con `sbctl` (claves propias, sin depender del certificado de Microsoft) y volver a sellar el secreto de este puente con `clevis encrypt tpm2 '{"pcr_ids":"7"}'` en vez de `'{}'` — cambio de una sola línea sobre el mismo diseño, no hace falta rehacer nada de lo implementado ahora.

### 7.2 — Reconstruir huella en el lockscreen de Quickshell
Conectar `quickshell-fprint` a `LockAuth.qml` con un segundo `PamContext` en paralelo al de contraseña (arquitectura ya validada en sesiones previas, solo falta reimplementarla — y esta vez confirmar que persiste en disco antes de darla por cerrada).

### 7.3 — SDDM: ¿hace falta clonar y parchear el repo?
**No para el bug del keyring** — la causa es 100% de configuración PAM, no de SDDM en sí. Clonar/parchear SDDM sí tendría sentido si en el futuro querés UI de huella real en el greeter (ícono, estado, mensaje "coloca el dedo") en vez del mensaje genérico actual — pero es un esfuerzo aparte, no bloqueante para arreglar el keyring.

### 7.4 — "Windows Hello" en Linux — qué tan cerca se puede estar
- **Login/lock/sudo con biometría**: es exactamente `fprintd` + PAM, que ya tenés — el gap real está en la integración (§7.1/§7.2), no en la tecnología.
- **Passkeys/WebAuthn en sitios web** (la otra mitad de lo que hace Windows Hello): el soporte nativo de huella como "platform authenticator" en navegadores Linux todavía es inmaduro/inconsistente. Si te interesa esa parte, la opción más confiable hoy es una llave FIDO2 física (YubiKey o similar) en vez de intentar forzar la huella del laptop como autenticador de plataforma — pero es un tema aparte del audit de hoy, avisame si querés profundizar.

### 7.5 — Cerrar el gap de reproducibilidad
Una vez elegido el fix de 7.1, agregar a `bootstrap.sh` (paso nuevo, documentado en `CLAUDE.md`): instalar `fprintd`, insertar la línea correspondiente en `system-auth` (o no, según la opción elegida), y desplegar `system/pam.d/quickshell-fprint`.

---

## 8. Estado de la decisión (histórico)

~~Opción elegida: 7.1 — puente de credencial cacheada, sellado con `clevis encrypt tpm2 '{}'`~~ — **abandonado, ver §9**. Se implementó, se probó en vivo, y se descubrió que no funcionaba (§9.1). El fix real terminó siendo mucho más simple.

---

## 9. Solución final implementada (2026-08-04) — CONFIRMADA EN VIVO

### 9.1 — Por qué el puente TPM (§7.1) no funcionó

Se implementó dos veces, con dos mecanismos distintos, y ninguno funcionó — ambos intentos dejaron aprendizajes reales:

**Intento 1 — `gnome-keyring-daemon --unlock`/`--login` desde la fase `session`** (el diseño original de §7.1.2): se probó en vivo con un desbloqueo controlado por D-Bus (`Locked: true` → correr el script → seguía en `true`). Causa: `--unlock`/`--login` **no son llamadas IPC a un daemon ya corriendo** — son un mecanismo de arranque, solo tienen efecto si corren *antes* de que el daemon real se inicialice por primera vez. Nuestro paso corría en `session`, después de `pam_gnome_keyring.so auto_start` (que es justo lo que ya inicializa el daemon) — para cuando llamábamos `--unlock`, ya era tarde. Confirmado leyendo el código fuente real de `pam_gnome_keyring.so` (`gkr-pam-module.c`/`gkr-pam-client.c` en GNOME/gnome-keyring): el mecanismo real es `gkr_pam_client_run_operation()` hablando directo con el socket de control del daemon con un protocolo propio, no expuesto como CLI.

**Intento 2 — módulo PAM propio en Rust (`pam_authtok_tpm2`, crate en `system/pam-authtok-tpm2/`, retirado del repo)**: en vez de reimplementar el protocolo del daemon, la idea fue inyectar la contraseña descifrada en `PAM_AUTHTOK` *antes* de que corriera `pam_gnome_keyring.so`, para que ese módulo (sin modificar) hiciera su propio trabajo correctamente. Se validó con `pamtester` en aislamiento y funcionaba — pero **en el login real de SDDM nunca llegaba a ejecutarse**. Causa raíz (el hallazgo más importante de toda esta investigación): `sufficient` en PAM no corta solo "el resto del archivo incluido" — corta **toda la evaluación del stack combinado**, sin importar cuántos `include` estén encadenados. Como `pam_fprintd.so sufficient` vive dentro de `system-auth` (`sddm` → `include system-login` → `system-auth`), cuando la huella gana, PAM termina ahí mismo — ni nuestro módulo nuevo ni la línea original `-auth optional pam_gnome_keyring.so` de `/etc/pam.d/sddm` llegaban a correr jamás. Esto explica el bug original de punta a punta: `pam_gnome_keyring.so` nunca alcanzaba a guardar nada en su propia fase `auth` cuando ganaba la huella.

Explorar un tercer intento (escribir directamente en el dato interno `gkr_system_authtok` que usa `pam_gnome_keyring.so` para pasar la contraseña de `auth` a `session`) reveló que dependería de un detalle de implementación no garantizado de un proyecto externo — fue en ese punto que el usuario propuso el enfoque real, mucho mejor.

### 9.2 — La solución real: nunca dejar que la huella decida sola

Insight del usuario: en vez de intentar que la huella *también* desbloquee el keyring (que es donde fallaban los intentos 1 y 2), sacarle a la huella la capacidad de saltarse la contraseña. Si la contraseña se verifica siempre, el keyring se desbloquea siempre — gratis, con el mecanismo que ya funciona hoy, sin puentes ni módulos nuevos.

**`/etc/pam.d/sddm`** — la fase `auth` dejó de usar `include system-login` (por la razón exacta de §9.1: el `sufficient` de adentro corta todo) y pasó a ser una copia autocontenida de la lógica de `system-auth`, con un solo cambio:

```
auth        optional                    pam_fprintd.so          timeout=60
auth        required                    pam_faillock.so         preauth
-auth       [success=2 default=ignore]  pam_systemd_home.so
auth        [success=1 default=bad]     pam_unix.so             try_first_pass nullok
auth        [default=die]               pam_faillock.so         authfail
auth        optional                    pam_permit.so
auth        required                    pam_env.so
auth        required                    pam_faillock.so         authsucc
-auth       optional                    pam_gnome_keyring.so
-auth       optional                    pam_kwallet5.so
```

`pam_fprintd.so` pasó de `sufficient` a `optional` — ya no puede decidir el login por sí sola (éxito, falla o timeout, da igual). `pam_unix.so` sigue `required` justo después — la contraseña se verifica **siempre**, sin excepción, y por eso `pam_gnome_keyring.so` (sin tocar) se desbloquea con su mecanismo normal en el 100% de los logins.

UX resultante: tocás el sensor si querés (queda registrado, no hace nada más), y de cualquier forma el sistema pide la contraseña — casi inmediato si tocaste el sensor, o recién a los 60s si no lo tocaste (subido de 4s a propósito el 2026-08-04, para que en la práctica sea más costoso ignorar el lector y la huella se sienta "más necesaria" sin dejar de ser opcional). Nunca te bloquea: sensor roto o sucio simplemente cae a pedir contraseña, solo que tarda más en llegar ahí. `system-auth` (sudo, TTY) queda completamente intacto — ahí sigue siendo huella-o-contraseña, con su propio `timeout=4` sin cambios.

**Confirmado en vivo** (`journalctl`, boot del 2026-08-04 ~15:06-15:07, todavía con `timeout=4`), los dos caminos:
- Con huella (detectada en ~1.5s, sin timeout) → pidió contraseña igual → `gkr-pam: unlocked login keyring`
- Sin huella (timeout de 4s, "Verification timed out") → pidió contraseña → `gkr-pam: unlocked login keyring`
- `timeout` subido a 60s después de esta confirmación — mismo mecanismo, no hace falta reprobar el camino "con huella" (no depende del valor del timeout), pero si se quiere confirmar el camino "sin huella" con el valor nuevo, ahora tarda un minuto real en completarse.

### 9.3 — Qué se retiró

- `system/pam-authtok-tpm2/` (crate Rust completo) — borrado del repo.
- `/usr/lib/security/pam_authtok_tpm2.so` — desinstalado del sistema en vivo.
- El secreto sellado (`/etc/gnome-keyring-tpm2.jwe`) y el paquete `clevis`/`tpm2-tools` se dejaron instalados (no estorban, y quedan documentados acá por si en algún momento se retoma un enfoque que sí los necesite) — no están en ningún path activo del login.

### 9.4 — Pendiente

- **Reconocimiento facial para el lockscreen** — investigado en §11 (cámara IR real confirmada, `howdy` mantenido pero con 348 issues abiertas, emisor IR de este chip sin confirmar). Diferido, no descartado.
- ~~Reproducibilidad: agregar a `bootstrap.sh` el despliegue de `system/pam.d/sddm`~~ — **resuelto (2026-08-05)**. `dotfiles/bootstrap.sh`, sección "24. SDDM", ahora instala `fprintd` y despliega los 3 PAM services (`sddm`, `quickshell-fprint`, `quickshell-password`) a `/etc/pam.d/`.

---

## 10. Huella en el lockscreen de Quickshell (2026-08-04) — CONFIRMADA EN VIVO

§7.2/§9.4 ya resuelto. `modules/lock/LockAuth.qml` ahora corre un segundo `PamContext` (`config: "quickshell-fprint"`, el PAM service que ya existía sin usar) en paralelo al de contraseña — cualquiera de los dos desbloquea, sin que uno bloquee al otro.

**Diseño**:
- Se auto-inicia/aborta en `onFocusChanged` (junto con el reset de foco del password ya existente).
- `fingerprintState` (`listening`/`success`/`error`) maneja un ícono nuevo (glyph `0xf0237`, md-fingerprint de Nerd Fonts, `DepartureMono Nerd Font` en duro — **no** `Style.fontFamily`, porque `modules/lock/` tiene su propio sistema de theming (`LockConfig.qml`), deliberadamente independiente del `Colours`/`Style` que usa el resto del shell — se respetó esa separación reusando tokens existentes de `LockConfig` (`warningMessageNormalColor`/`warningMessageErrorColor`/`loginButtonActiveContentColor`) en vez de importar `Colours`.
- Éxito en cualquiera de los dos `PamContext` aborta el otro (evita conversaciones colgadas) y desbloquea.

**Bug encontrado y corregido en vivo** (el más relevante para futuras sesiones tocando este archivo): el primer diseño del reintento tras una huella incorrecta se guardaba con `if (root.focus) pamFingerprint.start()`. Se rompía de dos formas distintas, encontradas con logging en vivo (`qs log`, tag por instancia):
1. **`fprintd: Authorization denied ... Device was already claimed`** — reintentar demasiado rápido después de un fallo choca con la conversación anterior todavía liberando el device claim. `start()` devuelve `false` de forma síncrona en ese caso y **nunca dispara `completed()`/`error()`** — un reintento ingenuo de una sola vez se moría ahí para siempre. Fix: chequear el valor de retorno de `start()` y reintentar en loop hasta que agarre el dispositivo de verdad, no asumir que un solo reintento alcanza.
2. **`root.focus` no es confiable como gate** — confirmado en vivo que puede leer `false` justo después de una huella fallida sin que el usuario haya tocado nada más, y sin que `LockSurface.revealed` (de donde se supone que sale `focus`) haya cambiado tampoco — no se identificó la causa raíz exacta (bajo el protocolo de session-lock de Wayland nada más puede robar el foco mientras está bloqueado, así que no es una superficie externa; huele a particularidad interna de QtQuick con el binding `focus: root.revealed`, no confirmado). Fix pragmático: sacar el chequeo de `root.focus` del timer de reintento — `abort()` en `onFocusChanged` sigue siendo la señal real de "parar", pero el reintento ya no se auto-bloquea por una lectura de foco que no reflejaba la realidad.

**Confirmado en vivo por el usuario**: huella incorrecta → ícono marca error (rojo, grande) → reintenta solo → huella correcta después → desbloquea sin pedir contraseña.

**Animación de "escaneo activo" (2026-08-05) — CONFIRMADA EN VIVO**: `SequentialAnimation` (`scanPulse`) sobre `fingerprintIcon.opacity`, pulso 1.0↔0.35 en 900ms por tramo (`Easing.InOutSine`), loop infinito. Corre solo mientras `fingerprintState === "listening"` (no durante `success`/`error`, que se leen como respuestas estáticas, no actividad) y respeta `LockConfig.enableAnimations` — mismo gate que ya usa `LockSpinner.qml` para su `RotationAnimation`, por consistencia con la convención del proyecto. `onRunningChanged` resetea `opacity` a 1 cuando se detiene, para no dejar el ícono a mitad de pulso al pasar a `success`/`error`.

---

## 11. Panel `>security` en el launcher + bug de fondo en la contraseña del lockscreen (2026-08-05) — CONFIRMADO EN VIVO

**Reconocimiento facial (howdy) — descartado por ahora.** Se investigó (cámara IR real confirmada en `/dev/video2`/`video3`, formato `GREY` puro, típico sensor Windows-Hello; proyecto `howdy` mantenido pero con 348 issues abiertas, sin confirmación de que el emisor IR de este chip exacto —`30c9:005f`— encienda solo). Se decidió no integrarlo hasta no poder probarlo en vivo con garantías — queda pendiente, no descartado definitivamente.

**Panel `>security` — nuevo.** Comando de launcher siguiendo el patrón de `>screensaver` (`modules/launcher/SecurityForm.qml`, wiring en `LauncherContent.qml`). Gestiona:
- Toggle "Fingerprint unlock (lockscreen)" — `services/Security.qml` (singleton nuevo, mismo patrón FileView+`_restored` que `IdleManager.qml`, persiste en `~/.local/state/quickshell/security.json`).
- Estado de enrolamiento en vivo vía `fprintd-list`/`fprintd-enroll`/`fprintd-delete` (`Process`+`SplitParser`, protocolo `Enroll result: <status>` de fprintd — stages no-terminales como `enroll-stage-passed`/`enroll-retry-scan`/`enroll-swipe-too-short` vs. terminales `enroll-completed`/`enroll-failed`/etc.), con progreso en vivo por toque durante el enrolamiento.
- `LockAuth.qml`: `pamFingerprint.start()` (en `onFocusChanged` y en el timer de reintento) y el ícono de huella quedan gateados por `Security.fingerprintEnabled`.

**Bug encontrado en vivo #1 — asimetría en `pamFingerprint.abort()`.** El `onCompleted` de la contraseña llamaba `pamFingerprint.abort()` sin guardia (a diferencia del lado espejo, que sí chequeaba `pam.active` antes de abortar). Antes de esta sesión nunca importaba porque `pamFingerprint` siempre arrancaba junto con la contraseña — con el toggle nuevo, desactivar la huella significa que `pamFingerprint` nunca llega a estar activo, y `.abort()` sobre un contexto nunca iniciado tiraba, cortando la función antes de la línea que desbloquea. Fix: mismo guard `if (pamFingerprint.active)` en ambos lados (y también en el `else` de `onFocusChanged`).

**Bug encontrado en vivo #2 — el de fondo, mucho más importante.** Con el bug #1 ya arreglado, el usuario reportó que la contraseña sola desbloqueaba, pero no al instante — y que usar la huella durante esa espera desbloqueaba de inmediato, pese a tener el toggle desactivado. Diagnóstico con `console.log` temporal (`qs log`) descartó cualquier problema en el QML: `pam.onCompleted` daba `result=0` y `root.lock.locked = false` se ejecutaba limpio, sin excepciones.

La causa real estaba en el PAM del sistema, no en Quickshell: el `PamContext` de contraseña usaba `config: "passwd"` → `/etc/pam.d/passwd` hace `include system-auth` → **`system-auth` tiene su propio `auth sufficient pam_fprintd.so timeout=4` de PRIMERO en el stack** (el mismo patrón estructural ya documentado para SDDM en §3/§7.1, pero nunca corregido acá porque es el stock del sistema, compartido con sudo/su/TTY). Esto significaba que cada intento de contraseña en el lockscreen:
1. Primero esperaba hasta 4s a que `pam_fprintd` respondiera, ANTES de llegar a chequear la contraseña real (de ahí la demora).
2. Si tocabas el sensor en esa ventana, `pam_fprintd` ganaba por `sufficient` y desbloqueaba al toque **sin validar la contraseña en absoluto** — bypaseando por completo el toggle `Security.fingerprintEnabled`, que solo controla el `PamContext` propio (`quickshell-fprint`), no este stack del sistema.

**Fix**: nuevo servicio dedicado `system/pam.d/quickshell-password` (desplegado en `/etc/pam.d/quickshell-password`) — byte-a-byte igual al `auth` de `system-auth`, menos la línea de `pam_fprintd.so`. `LockAuth.qml`'s `pam` PamContext pasa de `config: "passwd"` a `config: "quickshell-password"`. sudo/su/TTY login siguen usando `system-auth` directo, sin tocar — mantienen huella-o-contraseña como antes.

**Confirmado en vivo por el usuario**: contraseña sola desbloquea al instante con la huella desactivada; con la huella activada, sigue funcionando como antes.

**Extensión — múltiples dedos (2026-08-05).** `>security` pasó de manejar un único dedo hardcodeado (`right-index-finger`) a gestionar cualquiera de los 10 nombres válidos de `fprintd` (confirmados contra el propio binario: `fprintd-enroll -f bogus-finger` devuelve la lista completa en su warning de "Invalid finger name"). Lista de dedos registrados (cada uno con su `×` de borrado individual, `fprintd-delete <user> -f <finger>` → `DeleteEnrolledFinger` por D-Bus, confirmado con `gdbus introspect` contra el servicio real — distinto de `DeleteEnrolledFingers` sin argumentos, que borra todos) + chips de dedos disponibles para agregar (`Flow`, uno por dedo no enrolado todavía). Panel con altura medida de `content.implicitHeight` en vez de una constante a mano, porque el contenido ahora es de longitud variable.

---

## 12. Agente polkit propio (2026-08-05) — CONFIRMADO EN VIVO

Al enrolar/borrar huellas apareció un popup de `polkit-gnome-authentication-agent-1` (GTK, tema Adwaita) pidiendo la contraseña — desencajaba visualmente del resto del shell. Investigado y confirmado con la política real (`/usr/share/polkit-1/actions/net.reactivated.fprint.device.policy`): la acción `net.reactivated.fprint.device.enroll` es `auth_self_keep` (pide confirmar que sos vos antes de agregar/borrar una huella, cacheado unos minutos) — a propósito, mismo criterio que Windows Hello, **no** es sudo ni está vinculado al login de SDDM (son 3 sistemas de auth completamente separados). Se decidió no aflojar esa política (debilitaría justo lo que el panel protege) y en cambio integrarla visualmente.

**Solución — Quickshell trae un agente polkit nativo.** `Quickshell.Services.Polkit` (`PolkitAgent`/`AuthFlow`, confirmado leyendo el código fuente en `/usr/src/debug/quickshell-git/`) permite implementar el agente completo en QML, sin escribir nada en C. Mismo patrón que `PamContext` (mensaje, prompt, `submit()`, señales de éxito/error/cancelado) pero para polkit.

**Diseño — reutiliza el launcher en vez de una ventana aparte** (pedido explícito del usuario, para mantener la línea visual): nuevo modo `"polkit"` en `LauncherContent.qml`, máxima prioridad sobre cualquier otro (`if (Polkit.active) return "polkit"`, sin importar lo que esté tipeado). Si el launcher está cerrado, se auto-abre (animación normal de apertura) y se auto-cierra al resolver la solicitud — pero **solo si fue el propio flujo el que lo abrió** (`root.polkitAutoOpened`); si ya estaba abierto en otro modo (p. ej. en medio del enrolamiento desde `>security`), lo deja abierto y vuelve a ese modo solo al terminar. `PolkitForm.qml` es genérico — `flow.message`/`flow.inputPrompt` vienen de la acción que sea (fprintd, udisks, lo que fuere), así que la misma UI sirve para cualquier solicitud del sistema, no solo huella.

**Iteración de diseño (pedido del usuario)**: la primera versión reusaba la barra de búsqueda del launcher como campo de contraseña (un solo input, mismo lugar visual de siempre). El usuario prefirió un campo propio dentro del panel, arriba de los botones Cancel/Submit, con la barra de búsqueda inerte debajo mostrando solo un placeholder genérico — mismo estilo de campo con borde que ya usa `WebAppForm.qml` (label arriba + `Rectangle` con borde que resalta en foco + `TextInput`). Carácter de máscara cambiado a `passwordCharacter: "*"` (el bullet `TextInput.Password` por defecto no calzaba con la estética del proyecto).

**Gotcha de registro — solo un agente polkit por sesión.** El registro (`PolkitAgent.componentComplete()`) corre una sola vez al arrancar Quickshell — si el agente GTK (`polkit-gnome-authentication-agent-1`, lanzado desde `hypr/.config/hypr/deadlock/execs.lua`) ya está corriendo en ese momento, polkit rechaza el registro (`An authentication agent already exists for the given subject`) y **no reintenta solo**. Hubo que: matar el proceso GTK, sacar la línea de `execs.lua` (para que no vuelva a arrancar en el próximo login), y reiniciar Quickshell (`pkill -f "^quickshell$" && quickshell & disown` — nota: `hyprctl dispatch exec quickshell` no funciona en este fork, usa el mismo puente Lua que ya documentamos para `dispatch`/`keyword`, sintaxis distinta a la de hyprctl estándar) para que el registro se reintentara con el slot ya libre.

**Manejo de Escape/Cancel (pedido del usuario) — 3 casos distintos, uno tenía un bug real**:
1. Esc navegando en `>security` (sin enrolar) → cierra el launcher entero, comportamiento genérico, ya funcionaba.
2. Esc en el campo de contraseña de polkit → `Polkit.cancel()`, ya estaba implementado desde el diseño inicial.
3. **Bug encontrado**: Esc a mitad de un enrolamiento de huella (`Security.enrolling === true`, sigue en modo `"security"`, no `"polkit"`) caía en el handler genérico de Esc y cerraba TODO el launcher sin avisarle a `fprintd-enroll`, dejándolo corriendo de fondo sin nada que lo cancele. Fix: chequeo explícito `if (root.mode === "security" && Security.enrolling) { Security.cancelEnroll(); return }` antes del cierre genérico — cancela el escaneo y vuelve a la lista de dedos, igual que ya hacía el botón "Cancel" de esa misma pantalla.

**Guard de doble-submit con Enter.** El botón Submit ya se ocultaba (`visible: isResponseRequired`) apenas se envía una respuesta, pero la tecla Enter en el campo no tenía el mismo resguardo — el campo puede retener foco un instante después de que `isResponseRequired` pasa a `false` (antes de que llegue la próxima etapa), y un segundo Enter en esa ventana reenviaba un string vacío. `Keys.onReturnPressed` ahora chequea `root.flow.isResponseRequired` igual que el botón.

**Verificado — funciona con acciones genéricas del sistema, no solo `fprintd`.** Probado con `pkexec whoami` (acción `org.freedesktop.policykit.pkexec`, sin relación a huella): el launcher se auto-abre igual, el panel es genérico (`flow.message`/`flow.inputPrompt` vienen de la acción que sea), y funciona de punta a punta. Confirmó algo más: **la huella también sirve para acciones de polkit en general**, no solo para el propio `quickshell-fprint`. Investigado y no es un bug — `/usr/lib/pam.d/polkit-1` (el PAM que usa polkit para toda autenticación) hace `include system-auth`, el mismo stack de siempre con `pam_fprintd.so sufficient timeout=4` de primero. Mismo patrón estructural que SDDM/lockscreen-password, pero acá es **comportamiento deseado**: no hay ningún toggle nuestro prometiendo "esto es solo contraseña" que esté siendo ignorado — es la misma lógica huella-o-contraseña que ya tiene `sudo`/`su`/TTY (tabla de decisiones del proyecto), ahora consistente también en polkit. Confirmado con el usuario, se deja así a propósito — no se creó un servicio `quickshell-`* dedicado para este caso.

**Confirmado en vivo por el usuario**: agente propio registra sin errores, prompt se ve integrado al estilo del launcher, campo de contraseña propio con `*`, Esc cancela el enrolamiento y vuelve a `>security` sin cerrar el launcher, y funciona igual con una acción de polkit ajena a huella (`pkexec`).
