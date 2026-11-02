# Time Register

Este repositorio **ya no contiene la app**. Solo mantiene las URLs antiguas de GitHub Pages y las redirige al sitio canónico.

- App y web: https://timeregister.davidmenendez.dev/
- Stubs públicos: https://davidmenendez9901.github.io/time_register/

Las rutas de la tabla son relativas a esa base (`/time_register/` en un *project site* de Pages).

## Mapa

| Archivo | URLs en Pages | Destino |
|---|---|---|
| `index.html` | `/`, `/index.html`, `/index` (HTTP 200) | https://timeregister.davidmenendez.dev/ |
| `privacy.html` | `/privacy.html`, `/privacy` (HTTP 200) | https://timeregister.davidmenendez.dev/privacidad/ |
| `404.html` | `/404.html` (HTTP 200) y cualquier otra ruta (HTTP 404, mismo cuerpo) | https://timeregister.davidmenendez.dev/ |
| `.nojekyll` | — | desactiva Jekyll; el sitio se sirve tal cual |

`index.html` y `404.html` son **el mismo contenido**. Si cambias la home, edita los dos.

### Pretty URLs y barra final

Pages sirve `nombre.html` también en `/nombre` (sin extensión y **sin barra**). `/privacy` y `/index` no son archivos extra.

Con barra (`/privacy/`, `/index/`) **no** hay alias: HTTP 404 y cuerpo de `404.html` → home del sitio nuevo.

No hay stub en español: `/privacidad` y `/privacidad/` aquí también caen al 404.

## Cómo redirige

No hay `301`/`302`. Pages sirve el HTML y el **cliente** salta.

Cada HTML usa cuatro capas que deben apuntar al mismo destino:

1. `<link rel="canonical">` — URL canónica para buscadores.
2. `<meta http-equiv="refresh" content="0; url=…">` — salto sin JavaScript.
3. `location.replace(…)` — salto inmediato en el navegador.
4. Enlaces visibles (ES y EN) — si el refresh y JS fallan.

`curl -I` solo muestra 200/404. El destino está en el cuerpo.

## Publicación

GitHub Pages (Settings → Pages; verificado en la API del repo):

- Branch `main`, carpeta `/`
- Builder clásico (`build_type: legacy`): no hay workflow en `.github/`
- `404.html` personalizado (`custom_404: true`)
- HTTPS forzado
- Sin `CNAME`: el dominio canónico es el sitio nuevo, no `github.io`

Las respuestas 200 llevan `Cache-Control: max-age=600` (~10 min). Tras un push, espera ese margen o fuerza recarga.

## Cambiar un destino

1. Actualiza las cuatro capas del HTML.
2. Si el destino es la home, replica el cambio en `index.html` y `404.html`.
3. En el sitio nuevo la política es `/privacidad/` (`/privacidad` sin barra hace 301 a esa URL). No apuntes stubs a `/privacy` ni `/privacy/` de ese host: `/privacy` redirige a `/privacy/`, que responde 404.
4. Comprueba en el **navegador**. Un servidor local no replica las pretty URLs de Pages (`/privacy` sin `.html`).

```bash
BASE=https://davidmenendez9901.github.io/time_register
curl -sI "$BASE/"                 # 200, salto a la home
curl -sI "$BASE/privacy"          # 200, mismo cuerpo que privacy.html
curl -sI "$BASE/privacy/"         # 404, cuerpo de 404.html
curl -sI "$BASE/index/"           # 404, igual
curl -sI "$BASE/404.html"         # 200: el fichero existe
curl -sI "$BASE/privacidad"       # 404: no hay stub en español
curl -s  "$BASE/privacy.html" | grep -E 'canonical|refresh|location.replace|href='
```

## Qué no hacer

- No republicar aquí la landing ni la política. El texto canónico está en el sitio nuevo.
- No conviertas estas páginas en un `301` de servidor: Pages no lo ofrece para archivos sueltos.
- No borres `.nojekyll`. Sin él, Jekyll puede ignorar o transformar ficheros.
- No trates `/privacy/` (barra en *este* sitio) como alias de la política.
- No restaures ni documentes la app Flutter aquí: ese código no está en este repo.
