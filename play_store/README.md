# Recursos y checklist para la actualización en Play Store

Todo lo necesario para subir la versión **1.1.1 (versionCode 4)** está en esta carpeta.

## ⚠️ PASO 0 — Restablecer la clave de subida (OBLIGATORIO)

La clave con la que se subió la primera versión se perdió, así que el `.aab`
nuevo (firmado con la clave nueva) será rechazado hasta restablecerla:

1. Play Console → tu app → **Configuración → Integridad de la app → Firma de apps**.
2. Pulsa **"Solicitar restablecimiento de la clave de subida"**.
3. Motivo: clave perdida.
4. Sube el certificado **`upload_certificate.pem`** (está en esta carpeta).
5. Envía la solicitud. Google la procesa normalmente en ~2 días hábiles y
   avisa por correo cuando la clave nueva queda activa.

La clave de subida (todas tus apps) está en
`/Users/d/Documents/keystores/menendez-upload.jks`
(alias `upload`; contraseña en `android/key.properties`, que no se versiona).
**Respalda el `.jks` y la contraseña fuera de esta máquina.** Huella SHA-256 del
certificado: `A4:79:1E:7A:FC:A1:D2:29:FE:06:10:E9:12:04:37:5B:FF:83:10:D0:F4:02:7B:15:88:A8:C3:34:4C:B8:87:5C`.

## Checklist de la actualización

- [ ] **Clave de subida restablecida** (paso 0; espera el correo de Google).
- [ ] **versionCode**: en Play Console revisa el versionCode más alto subido.
      Este árbol lleva **4** (`1.1.1+4` en `pubspec.yaml`); debe ser mayor
      que el existente. Si ya subiste un 4 o superior, sube el `+N` de
      `version:` y recompila. También actualiza el texto `'1.1.1'` en
      `lib/presentation/pages/settings_page.dart` (no se lee de pubspec).
- [x] **Package**: Play Console registró la app como
      `time_register.davidmenendez.dev`; el `applicationId` del proyecto ya
      se ajustó para coincidir (2026-07-06).
- [ ] **Subir `app-release.aab`** a **prueba interna** primero.
- [ ] **Probar la actualización** en un dispositivo que tenga la versión
      vieja instalada (las migraciones de base de datos v4 → v9 deben
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
- [ ] **Política de privacidad** (actualizada 23 sep 2026: Android + iPhone/iPad/Mac,
      exportaciones por la hoja de compartir, Auto Backup de Google desactivado,
      iCloud/Time Machine pueden incluir datos en Apple):
      - Play Console (blob del repo):
        `https://github.com/davidmenendez9901/time_register/blob/main/PRIVACY_POLICY.md`
      - Página publicada (la que abre la app):
        `https://davidmenendez9901.github.io/time_register/privacy.html`
      Mantén ambos archivos (`PRIVACY_POLICY.md` y `docs/privacy.html`) iguales. El
      diálogo in-app (`privacyPolicyContent` en los ARB) es un **resumen corto**,
      no la política completa.
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
# 1. Sube la versión en pubspec.yaml (ej. 1.1.1+5; el +N es versionCode)
#    y el texto de versión en Settings (settings_page.dart)
# 2. Compila firmado:
flutter build appbundle --release
# 3. El .aab queda en build/app/outputs/bundle/release/
```
