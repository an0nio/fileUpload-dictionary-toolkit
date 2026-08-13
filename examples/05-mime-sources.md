# 05 - Fuentes de MIME types

## Objetivo

Tener claro qué listas de MIME types usar sin añadir otro script innecesario.

La herramienta no genera MIME types porque ya hay dos fuentes suficientes:

```text
wordlists/custom/upload_common_mime.txt
wordlists/external/seclists-all-content-types.txt
```

La primera es pequeña y práctica. La segunda es amplia y depende de SecLists.

---

## Cuándo usar cada una

| Fuente | Cuándo usarla | Ventaja | Coste |
|---|---|---|---|
| `upload_common_mime.txt` | Primera pasada, labs, docencia | Corta y entendible | Menor cobertura |
| `seclists-all-content-types.txt` | Cobertura amplia | Muchas variantes reales | Más ruido |
| Perfil generado manual | Caso concreto: solo imágenes, XML, PHP-like | Muy enfocado | Hay que crearlo |

---

## Comprobar disponibilidad

```bash
cd /opt/fileUpload

ls -l wordlists/custom/upload_common_mime.txt
ls -l wordlists/external/seclists-all-content-types.txt
```

Si el symlink externo no existe:

```bash
bin/setup_symlinks.sh
```

Comprobar symlinks rotos:

```bash
find wordlists/external -xtype l
```

Si no imprime nada, no hay symlinks rotos.

---

## Perfil quick: MIME comunes de upload

Este fichero ya debería existir:

```text
wordlists/custom/upload_common_mime.txt
```

Contenido típico:

```text
image/jpeg
image/png
image/gif
image/svg+xml
text/plain
text/html
application/octet-stream
application/x-php
application/x-httpd-php
application/php
application/pdf
application/zip
application/xml
text/xml
```

Si quieres una copia en `generated/`:

```bash
cp wordlists/custom/upload_common_mime.txt \
   wordlists/generated/mime_upload_quick.txt
```

---

## Perfil solo imágenes

Útil cuando la app dice permitir solo imágenes:

```bash
grep '^image/' wordlists/custom/upload_common_mime.txt \
  | sort -u \
  > wordlists/generated/mime_images_quick.txt
```

Salida esperada:

```text
image/gif
image/jpeg
image/png
image/svg+xml
```

Si quieres ampliar desde SecLists:

```bash
grep '^image/' wordlists/external/seclists-all-content-types.txt \
  | sort -u \
  > wordlists/generated/mime_images_full.txt
```

---

## Perfil SVG/XML/documentos

Útil para uploads limitados donde el impacto puede venir por SVG, XML, PDF u Office:

```bash
cat > wordlists/generated/mime_xml_documents.txt <<'EOF_MIME'
image/svg+xml
application/xml
text/xml
application/pdf
application/zip
application/vnd.openxmlformats-officedocument.wordprocessingml.document
application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
application/vnd.openxmlformats-officedocument.presentationml.presentation
EOF_MIME
```

Cuándo tiene sentido:

```text
[ ] La app acepta documentos.
[ ] La app genera preview.
[ ] Hay parser server-side.
[ ] Quieres probar rutas XML-like o viewers.
```

---

## Perfil PHP-related

Útil cuando quieres probar si la validación mira solo MIME o si acepta tipos raros:

```bash
cat > wordlists/generated/mime_php_related.txt <<'EOF_MIME'
text/plain
text/html
application/octet-stream
application/x-php
application/x-httpd-php
application/php
text/php
EOF_MIME
```

---

## Perfil archivos comprimidos

Útil si el endpoint acepta paquetes o adjuntos:

```bash
cat > wordlists/generated/mime_archives.txt <<'EOF_MIME'
application/zip
application/x-zip-compressed
application/x-tar
application/gzip
application/x-gzip
application/x-7z-compressed
application/x-rar-compressed
EOF_MIME
```

---

## Perfil amplio: custom + SecLists

```bash
cat \
  wordlists/custom/upload_common_mime.txt \
  wordlists/external/seclists-all-content-types.txt \
  | tr -d '\r' \
  | sed 's/#.*$//' \
  | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
  | sed '/^$/d' \
  | sort -u \
  > wordlists/generated/mime_all_combined.txt
```

---

## Perfiles recomendados

Mantén varios ficheros generados y elige según hipótesis:

```text
wordlists/generated/mime_upload_quick.txt
wordlists/generated/mime_images_quick.txt
wordlists/generated/mime_images_full.txt
wordlists/generated/mime_xml_documents.txt
wordlists/generated/mime_php_related.txt
wordlists/generated/mime_archives.txt
wordlists/generated/mime_all_combined.txt
```

## Nota metodológica

El MIME type es una capa más del upload, no sustituye al filename ni al contenido real.

```text
filename      → shell.jpg%00.phar
Content-Type  → image/jpeg
magic bytes   → FF D8 FF / GIF89a / PNG signature
contenido     → snippet o archivo real
```
