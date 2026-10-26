# Time Register

Este repositorio **ya no contiene la app**. Solo mantiene las direcciones antiguas de GitHub Pages y las redirige al sitio nuevo.

La app y su web están en https://timeregister.davidmenendez.dev/.

URL pública de este repo: https://davidmenendez9901.github.io/time_register/

## Mapa

| Archivo | URLs en Pages | Destino |
|---|---|---|
| `index.html` | `/`, `/index.html`, `/index` | https://timeregister.davidmenendez.dev/ |
| `privacy.html` | `/privacy.html`, `/privacy` | https://timeregister.davidmenendez.dev/privacidad/ |
| `404.html` | cualquier otra ruta (HTTP 404) | https://timeregister.davidmenendez.dev/ |
| `.nojekyll` | — | desactiva Jekyll; el sitio se sirve tal cual |

GitHub Pages también expone `nombre.html` en `/nombre` (sin extensión y **sin barra final**). Eso no es un archivo extra: `/privacy` y `/index` son el mismo HTML que `privacy.html` e `index.html`.

`/privacy/` (con barra) **no** sirve `privacy.html`. Responde 404 con el cuerpo de `404.html` y acaba en la home del sitio nuevo.

## Cómo redirige

No hay redirección HTTP `301`/`302`. GitHub Pages sirve el HTML (`200` en las URLs del mapa; `404` en el resto, con el cuerpo de `404.html`) y el cliente salta.

Cada página usa **cuatro capas** que deben apuntar al mismo destino:

1. `<link rel="canonical">` — URL canónica para buscadores.
2. `<meta http-equiv="refresh" content="0; url=…">` — salto sin JavaScript.
3. `location.replace(…)` — salto inmediato en el navegador.
4. Enlaces visibles (ES y EN) — si el refresh y JS fallan.

`index.html` y `404.html` son copias a propósito. Si cambias la home, edita **los dos**.

## Publicación

GitHub Pages (Settings → Pages; verificado en la API del repo):

- Branch: `main`, carpeta `/`
- `404.html` personalizado (`custom_404: true`)
- HTTPS forzado
- Sin `CNAME`: el dominio canónico es el sitio nuevo, no `github.io`

La CDN de Pages cachea unos **10 minutos** (`Cache-Control: max-age=600`). Un cambio puede tardar eso en verse.

## Cambiar un destino

1. Actualiza las cuatro capas del HTML correspondiente.
2. Si el destino es la home, replica el cambio en `index.html` y `404.html`.
3. No inventes rutas en el sitio nuevo: la política vive en `/privacidad/`. `/privacy` y `/privacy/` del sitio nuevo no sirven esa página (`/privacy` redirige a `/privacy/`, que responde 404).
4. Comprueba en el navegador. El `meta refresh` y `location.replace` no se ven en `curl -I`.

```bash
# Las stubs responden 200/404; el salto está en el HTML
curl -sI https://davidmenendez9901.github.io/time_register/
curl -s  https://davidmenendez9901.github.io/time_register/privacy.html | grep -E 'canonical|refresh|location.replace|href='
curl -sI https://davidmenendez9901.github.io/time_register/privacy          # 200, mismo cuerpo que privacy.html
curl -sI https://davidmenendez9901.github.io/time_register/privacy/         # 404, cuerpo de 404.html
curl -sI https://davidmenendez9901.github.io/time_register/ruta-inexistente # 404 + cuerpo de 404.html
```

## Qué no hacer

- No vuelvas a publicar la política ni la landing aquí. El texto canónico está en el sitio nuevo.
- No conviertas estas páginas en un `301` de servidor: GitHub Pages no lo ofrece para archivos sueltos.
- No borres `.nojekyll`. Sin él, Jekyll puede ignorar o transformar ficheros.
- No apuntes un stub a `/privacy` ni a `/privacy/` del sitio nuevo. El slug canónico es `/privacidad/`.
- No trates `/privacy/` (barra final en *este* sitio) como alias de la política: esa ruta cae al 404 y a la home.
