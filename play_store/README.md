# Recursos y checklist para la actualización en Play Store

Todo lo necesario para subir la versión **1.1.0 (versionCode 2)** está en esta carpeta.

## ⚠️ PASO 0 — Restablecer la clave de subida (OBLIGATORIO)

La clave con la que se subió la primera versión se perdió, así que el `.aab`
nuevo (firmado con la clave nueva) será rechazado hasta restablecerla:

1. Play Console → tu app → **Configuración → Integridad de la app → Firma de apps**.
2. Pulsa **"Solicitar restablecimiento de la clave de subida"**.
3. Motivo: clave perdida.
4. Sube el certificado **`upload_certificate.pem`** (está en esta carpeta).
5. Envía la solicitud. Google la procesa normalmente en ~2 días hábiles y
   avisa por correo cuando la clave nueva queda activa.

La clave nueva vive en `/home/david/keystores/time_register-release.jks`
(contraseña en `android/key.properties`). **Respalda ambos archivos fuera de
esta máquina** para no repetir este trámite.

## Checklist de la actualización

- [ ] **Clave de subida restablecida** (paso 0; espera el correo de Google).
- [ ] **versionCode**: en Play Console revisa el versionCode más alto subido.
      Este build lleva **2**; debe ser mayor que el existente. Si ya subiste
      un 2 o superior, sube `version:` en `pubspec.yaml` (p. ej. `1.1.0+3`)
      y recompila.
- [ ] **Package**: el de Play Console debe ser exactamente
      `dev.davidmenendez.time_register`. Si no coincide, avísame antes de
      subir nada.
- [ ] **Subir `app-release.aab`** a **prueba interna** primero.
- [ ] **Probar la actualización** en un dispositivo que tenga la versión
      vieja instalada (las migraciones de base de datos v4 → v8 deben
      conservar tus entradas). No desinstales: actualiza encima.
- [ ] **Notas de versión**: copia `release_notes/es-ES.txt` y `en-US.txt`
      en el formulario de la versión.
- [ ] **Ficha de la tienda** (cambió mucho desde la primera versión):
  - [ ] Ícono nuevo: `icon_512.png` (antes era el ícono por defecto de Flutter).
  - [ ] Gráfico de funciones: `feature_graphic_1024x500.png`.
  - [ ] Capturas nuevas: `screenshots/phone/` (la UI fue rediseñada).
  - [ ] Descripciones: `listing/es-ES.txt` y `listing/en-US.txt`
        (nombre, corta y completa, dentro de los límites de caracteres).
  - [ ] Sitio web: `https://davidmenendez9901.github.io/time_register/`
- [ ] **Política de privacidad**:
      `https://github.com/davidmenendez9901/time_register/blob/main/PRIVACY_POLICY.md`
- [ ] **Seguridad de los datos**: declarar que **no se recolecta ni comparte
      ningún dato**. Si el formulario anterior decía otra cosa, actualízalo —
      ahora es verificable: la app ya no pide el permiso de internet.
- [ ] **Clasificación de contenido / público objetivo**: sin cambios
      esperados, pero revisa que no haya cuestionarios pendientes.
- [ ] Promover de prueba interna a producción cuando valides todo.

## Contenido de la carpeta

| Archivo | Uso |
|---|---|
| `app-release.aab` | El bundle firmado (no se versiona en git) |
| `upload_certificate.pem` | Certificado para el restablecimiento de clave |
| `icon_512.png` | Ícono de la ficha (512×512) |
| `feature_graphic_1024x500.png` | Gráfico de funciones |
| `screenshots/phone/` | 5 capturas (incluye modo oscuro) |
| `release_notes/` | Notas de versión es/en (máx. 500 caracteres) |
| `listing/` | Nombre, descripción corta y completa es/en |

## Para futuras versiones

```bash
# 1. Sube la versión en pubspec.yaml (ej. 1.1.1+3)
# 2. Compila firmado:
flutter build appbundle --release
# 3. El .aab queda en build/app/outputs/bundle/release/
```
