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
| `404.html` | `/404.html`, `/404` (HTTP 200) y cualquier otra ruta (HTTP 404, mismo cuerpo) | https://timeregister.davidmenendez.dev/ |
| `.nojekyll` | `/.nojekyll` (HTTP 200, cuerpo vacío) | desactiva Jekyll; el sitio se sirve tal cual |

`index.html` y `404.html` son **el mismo contenido**. Si cambias la home, edita los dos.

### Pretty URLs, barra final y mayúsculas

Pages sirve `nombre.html` también en `/nombre` (sin extensión y **sin barra**). `/privacy`, `/index` y `/404` no son archivos extra.

Con barra (`/privacy/`, `/index/`, `/404/`) **no** hay alias: HTTP 404 y cuerpo de `404.html` → home del sitio nuevo.

Las rutas son **case-sensitive**. `/Privacy`, `/PRIVACY`, `/INDEX` o `/Index.html` no coinciden con los ficheros y caen al 404.

No hay stub en español: `/privacidad` y `/privacidad/` aquí también caen al 404.

Query strings (`?utm=…`) no cambian el archivo servido. El salto del cliente **no** las reenvía al sitio nuevo.

## Cómo redirige

En HTTPS, este *project site* no hace `301`/`302` de contenido: Pages sirve el HTML y el **cliente** salta. La única redirección HTTP de este host es GitHub forzando HTTPS (`http://…github.io/…` → `https://…`, 301).

Cada HTML usa cuatro capas que deben apuntar al mismo destino:

1. `<link rel="canonical">` — URL canónica para buscadores.
2. `<meta http-equiv="refresh" content="0; url=…">` — salto sin JavaScript.
3. `location.replace(…)` — salto inmediato en el navegador.
4. Enlaces visibles (ES y EN) — si el refresh y JS fallan.

`curl -I` solo muestra 200/404. El destino está en el cuerpo.

## Publicación

GitHub Pages (Settings → Pages; verificado en la API del repo):

- Branch `main`, carpeta `/`
- Builder clásico (`build_type: legacy`): no hay workflow en `.github/`. GitHub ejecuta el workflow interno `pages-build-deployment` (no está en este repo).
- `404.html` personalizado (`custom_404: true`)
- HTTPS forzado (`https_enforced`, más HSTS `max-age=31556952`)
- Sin `CNAME`: el dominio canónico es el sitio nuevo, no `github.io`

Las respuestas **200** llevan `Cache-Control: max-age=600` (~10 min). Las **404** no anuncian `max-age`, pero la CDN igual puede servir HIT. Tras un push, espera ese margen o fuerza recarga.

El último build publicado sigue siendo `bbf2365` (15 oct 2026). Un cambio de README no se ve en Pages hasta que se mergea a `main`.

## Cambiar un destino

1. Actualiza las cuatro capas del HTML.
2. Si el destino es la home, replica el cambio en `index.html` y `404.html`.
3. En el sitio nuevo la política es `/privacidad/` (`/privacidad` sin barra hace 301 a esa URL). No apuntes stubs a `/privacy` ni `/privacy/` de ese host: `/privacy` redirige a `/privacy/`, que responde 404. Tampoco existen allí `/privacy.html` ni `/privacidad.html`.
4. Comprueba en el **navegador** y en minúsculas. Un servidor local no replica las pretty URLs de Pages (`/privacy` sin `.html`) ni el 404 personalizado.

```bash
BASE=https://davidmenendez9901.github.io/time_register
curl -sI "$BASE/"                 # 200, salto a la home
curl -sI "$BASE/privacy"          # 200, mismo cuerpo que privacy.html
curl -sI "$BASE/privacy/"         # 404, cuerpo de 404.html
curl -sI "$BASE/index/"           # 404, igual
curl -sI "$BASE/404"              # 200: pretty URL de 404.html
curl -sI "$BASE/404.html"         # 200: el fichero existe
curl -sI "$BASE/Privacy"          # 404: case-sensitive
curl -sI "$BASE/privacidad"       # 404: no hay stub en español
curl -sI "http://davidmenendez9901.github.io/time_register/"  # 301 a HTTPS
curl -s  "$BASE/privacy.html" | grep -E 'canonical|refresh|location.replace|href='
```

## Qué no hacer

- No republicar aquí la landing ni la política. El texto canónico está en el sitio nuevo.
- No conviertas estas páginas en un `301` de servidor: Pages no lo ofrece para archivos sueltos.
- No borres `.nojekyll`. Sin él, Jekyll puede ignorar o transformar ficheros.
- No trates `/privacy/` (barra en *este* sitio) como alias de la política.
- No asumas que `/Privacy` o `/INDEX` redirigen a la política o a la home *como alias*: son 404.
- No restaures ni documentes la app Flutter aquí: ese código no está en este repo.
