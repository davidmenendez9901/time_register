# Time Register

Este repositorio **ya no contiene la app**. Solo mantiene las direcciones antiguas de GitHub Pages y las redirige al sitio nuevo.

La app y su web están en https://timeregister.davidmenendez.dev/.

## Mapa

| Archivo | URL en Pages | Destino |
|---|---|---|
| `index.html` | `/` | https://timeregister.davidmenendez.dev/ |
| `privacy.html` | `/privacy.html` | https://timeregister.davidmenendez.dev/privacidad/ |
| `404.html` | cualquier otra ruta | https://timeregister.davidmenendez.dev/ |
| `.nojekyll` | — | desactiva Jekyll (sitio estático tal cual) |

URL pública de este repo:

https://davidmenendez9901.github.io/time_register/

## Cómo redirige

No hay redirección HTTP `301`/`302`. GitHub Pages sirve el HTML (`200` en `/` y `/privacy.html`; `404` en rutas desconocidas, con el cuerpo de `404.html`) y el cliente salta.

Cada página usa **cuatro capas** que deben apuntar al mismo destino:

1. `<link rel="canonical">` — URL canónica para buscadores.
2. `<meta http-equiv="refresh" content="0; url=…">` — salto sin JavaScript.
3. `location.replace(…)` — salto inmediato en el navegador.
4. Enlaces visibles (ES y EN) — si el refresh y JS fallan.

`index.html` y `404.html` son copias a propósito. Si cambias la home, edita **los dos**.

## Publicación

GitHub Pages está configurado así (Settings → Pages):

- Branch: `main`, carpeta `/`
- `404.html` personalizado
- HTTPS forzado
- Sin `CNAME`: el dominio canónico es el sitio nuevo, no `github.io`

La CDN de Pages cachea unos **10 minutos** (`Cache-Control: max-age=600`). Un cambio puede tardar eso en verse.

## Cambiar un destino

1. Actualiza las cuatro capas del HTML correspondiente.
2. Si el destino es la home, replica el cambio en `index.html` y `404.html`.
3. No inventes rutas en el sitio nuevo: hoy la política vive en `/privacidad/`, no en `/privacy`.
4. Comprueba en el navegador (el `meta refresh` y `location.replace` no se ven en `curl -I`).

```bash
# Las stubs responden 200/404; el salto es en el HTML
curl -sI https://davidmenendez9901.github.io/time_register/
curl -s  https://davidmenendez9901.github.io/time_register/privacy.html | grep -E 'canonical|refresh|location.replace|href='
curl -sI https://davidmenendez9901.github.io/time_register/ruta-inexistente   # 404 + cuerpo de 404.html
```

## Qué no hacer

- No vuelvas a publicar la política ni la landing aquí. El texto canónico está en el sitio nuevo.
- No conviertas estas páginas en un `301` de servidor: GitHub Pages no lo ofrece para archivos sueltos.
- No borres `.nojekyll`. Sin él, Jekyll puede ignorar o transformar ficheros.
- No asumas que `/privacy` (sin `.html`) existe. La ruta estable de este repo es `/privacy.html`.
