# 02 - PHP contra allowlist de imágenes por defecto

## Objetivo

Generar filenames evasivos para un escenario típico donde la aplicación permite extensiones de imagen comunes:

```text
.jpg
.jpeg
.png
.gif
```

La salida combina esas extensiones permitidas con extensiones PHP peligrosas/interesantes.

## Cuándo usarlo

Usa este perfil cuando:

```text
[ ] La app acepta varias extensiones de imagen
[ ] No quieres limitarte a .jpg
[ ] Quieres un perfil PHP general y reutilizable
[ ] Estás preparando una wordlist base para laboratorios PHP
```

## Generación usando defaults

```bash
cd /opt/fileUpload
bin/gen_filename_wordlist.sh
```

Con defaults, el script usa:

| Entrada | Ruta |
|---|---|
| Dangerous extensions | `wordlists/custom/php_exts.txt` |
| Allowed extensions | `wordlists/custom/allowed_image_exts.txt` |
| Output | `wordlists/generated/evasive_filenames.txt` |

## Generación explícita

Si prefieres salida con nombre más descriptivo:

```bash
bin/gen_filename_wordlist.sh \
  wordlists/custom/php_exts.txt \
  wordlists/generated/php_image_evasive.txt \
  wordlists/custom/allowed_image_exts.txt
```

## Comprobar allowlist usada

```bash
cat wordlists/custom/allowed_image_exts.txt
```

Salida esperada:

```text
.jpg
.jpeg
.png
.gif
```

## Ejemplos de salida esperada

```text
shell.php.jpg
shell.php.jpeg
shell.php.png
shell.php.gif
shell.jpg.php
shell.jpeg.php
shell.png.php
shell.gif.php
shell.phtml.jpg
shell.jpg.phtml
shell.phar.png
shell.png.phar
shell.php%00.gif
shell.gif%00.php
```

## Diferencia con el ejemplo 01

| Ejemplo | Allowed extensions | Uso |
|---|---|---|
| `01-php-jpg-only.md` | solo `.jpg` | whitelist estricta |
| `02-php-images-default.md` | `.jpg`, `.jpeg`, `.png`, `.gif` | allowlist de imágenes común |

## Variante: salida quick y full

Puedes mantener dos salidas:

```bash
bin/gen_filename_wordlist.sh \
  wordlists/custom/php_exts.txt \
  wordlists/generated/php_images_quick.txt \
  wordlists/custom/allowed_image_exts.txt
```

Y otra más amplia si amplías manualmente `php_exts.txt` o creas una lista propia:

```bash
bin/gen_filename_wordlist.sh \
  wordlists/generated/my_php_exts_extended.txt \
  wordlists/generated/php_images_full.txt \
  wordlists/custom/allowed_image_exts.txt
```
