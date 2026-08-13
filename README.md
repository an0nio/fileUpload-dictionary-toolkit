# fileUpload dictionary toolkit

Toolkit pequeño para **crear diccionarios y snippets reutilizables para pruebas de file upload**.

No es un wrapper de `ffuf`, Burp, curl ni ninguna herramienta de explotación. Su objetivo es ayudarte a preparar listas y plantillas que luego usarás como quieras.

```text
La herramienta genera diccionarios. El usuario decide cómo usarlos.
```

---

## Idea de origen

La herramienta nace como una extensión de una idea clásica de HTB: generar combinaciones evasivas de nombres de archivo a partir de:

- una lista de extensiones peligrosas/interesantes
- una lista de separadores o caracteres conflictivos
- una extensión permitida por la aplicación

Ejemplo base:

```bash
for char in '%20' '%0a' '%00' '%0d0a' '/' '.\\' '.' '…' ':'; do
    for ext in '.php' '.php3' '.php4' '.php5' '.php7' '.pht' '.phps' '.phar' '.phpt' '.pgif' '.phtml' '.phtm' '.inc' ; do
        echo "shell$char$ext.jpg" >> wordlist.txt
        echo "shell$ext$char.jpg" >> wordlist.txt
        echo "shell.jpg$char$ext" >> wordlist.txt
        echo "shell.jpg$ext$char" >> wordlist.txt
    done
done
```

Conceptualmente, esto es el **producto cartesiano** de varios conjuntos:

```text
extensiones peligrosas × separadores × extensiones permitidas × patrones de filename
```

Este toolkit generaliza esa idea para que no tengas que editar bucles a mano cada vez.

---

## Qué puede generar u organizar

| Área | Qué aporta |
|---|---|
| Filenames evasivos | Combina extensiones peligrosas con extensiones permitidas y separadores conflictivos |
| Extensiones peligrosas | Listas custom para PHP, ASP.NET, JSP y combinaciones propias |
| Extensiones permitidas | Listas de allowlist como `.jpg`, `.png`, `.gif`, `.pdf`, etc. |
| MIME types | Fuentes listas para usar: lista custom y SecLists si está disponible |
| Contenido manual | Snippets PHP, ASPX, JSP, SSI, EJS, `.htaccess`, etc. |
| Magic numbers | Firmas copiables para prefijar contenido manualmente |
| Candidatos GET | Convierte filenames aceptados en variantes razonables para pedir por URL |
| Examples | Casos de uso concretos para recordar cómo generar diccionarios |

---

## Estructura esperada

```text
/opt/fileUpload/
├── bin/
│   ├── gen_filename_wordlist.sh
│   ├── gen_get_candidates.py
│   ├── build_extension_wordlist.sh
│   ├── setup_symlinks.sh
│   ├── clean_results.sh
│   └── install.sh
├── wordlists/
│   ├── custom/
│   │   ├── php_exts.txt
│   │   ├── asp_exts.txt
│   │   ├── jsp_exts.txt
│   │   ├── allowed_image_exts.txt
│   │   ├── upload_common_mime.txt
│   │   └── upload_fieldnames.txt
│   ├── external/
│   │   └── seclists-*.txt
│   ├── generated/
│   └── content/
│       ├── php/
│       ├── aspnet/
│       ├── jsp/
│       ├── ssi/
│       ├── node/
│       └── magic_numbers/
├── requests/
├── results/
└── examples/
```

La separación importante es:

```text
wordlists/custom/      listas pequeñas, curadas y versionables
wordlists/external/    symlinks a fuentes externas como SecLists
wordlists/generated/   salidas generadas por scripts
wordlists/content/     snippets y referencias copiables
examples/              recetas prácticas de generación
```

---

## Instalación

Desde el repo clonado:

```bash
sudo ./bin/install.sh /opt/fileUpload
cd /opt/fileUpload
```

Crear symlinks a SecLists si está instalado:

```bash
bin/setup_symlinks.sh
```

Comprobar symlinks rotos:

```bash
find wordlists/external -xtype l
```

Si no imprime nada, no hay symlinks rotos.

---

# 1. Generar filenames evasivos

Script principal:

```bash
bin/gen_filename_wordlist.sh [dangerous_exts_file] [output_file] [allowed_exts_file]
```

Argumentos:

| Argumento | Descripción | Default |
|---|---|---|
| `dangerous_exts_file` | Extensiones peligrosas/interesantes | `wordlists/custom/php_exts.txt` |
| `output_file` | Archivo generado | `wordlists/generated/evasive_filenames.txt` |
| `allowed_exts_file` | Extensiones permitidas por la app | `wordlists/custom/allowed_image_exts.txt` |

La idea es generar patrones como:

```text
shell{dangerous}{allowed}
shell{allowed}{dangerous}
shell{dangerous}{separator}{allowed}
shell{allowed}{separator}{dangerous}
shell{separator}{dangerous}{allowed}
shell{allowed}{dangerous}{separator}
```

Ejemplos de separadores usados:

```text
%20
%09
%0a
%00
%0d%0a
/
.\
.
..
...
…
:
```

---

## 1.1 Uso por defecto: PHP contra allowlist de imágenes

Usa:

- peligrosas: `wordlists/custom/php_exts.txt`
- permitidas: `wordlists/custom/allowed_image_exts.txt`
- salida: `wordlists/generated/evasive_filenames.txt`

```bash
cd /opt/fileUpload

bin/gen_filename_wordlist.sh
```

Salida:

```text
wordlists/generated/evasive_filenames.txt
```

---

## 1.2 PHP contra whitelist solo `.jpg`

Crear allowlist temporal:

```bash
printf '.jpg\n' > wordlists/generated/allowed_jpg_only.txt
```

Generar diccionario:

```bash
bin/gen_filename_wordlist.sh \
  wordlists/custom/php_exts.txt \
  wordlists/generated/php_jpg_only.txt \
  wordlists/generated/allowed_jpg_only.txt
```

Ejemplos de salida esperada:

```text
shell.php.jpg
shell.jpg.php
shell.phtml.jpg
shell.jpg.phtml
shell.phar.jpg
shell.jpg.phar
shell.php%00.jpg
shell.jpg%00.php
shell.php%0a.jpg
shell.jpg%0a.phtml
```

---

## 1.3 PHP contra `.jpg` y `.png`

```bash
cat > wordlists/generated/allowed_jpg_png.txt <<'EOF'
.jpg
.png
EOF

bin/gen_filename_wordlist.sh \
  wordlists/custom/php_exts.txt \
  wordlists/generated/php_jpg_png.txt \
  wordlists/generated/allowed_jpg_png.txt
```

---

## 1.4 ASP.NET contra imágenes

```bash
bin/gen_filename_wordlist.sh \
  wordlists/custom/asp_exts.txt \
  wordlists/generated/aspnet_image_evasive.txt \
  wordlists/custom/allowed_image_exts.txt
```

Ejemplos de salida:

```text
shell.aspx.jpg
shell.jpg.aspx
shell.ashx.jpg
shell.jpg.ashx
shell.config.jpg
shell.jpg.config
```

---

## 1.5 JSP contra imágenes

```bash
bin/gen_filename_wordlist.sh \
  wordlists/custom/jsp_exts.txt \
  wordlists/generated/jsp_image_evasive.txt \
  wordlists/custom/allowed_image_exts.txt
```

Ejemplos de salida:

```text
shell.jsp.jpg
shell.jpg.jsp
shell.jspx.jpg
shell.jpg.jspx
shell.war.jpg
shell.jpg.war
```

---

## 1.6 Stack desconocido: PHP + ASP.NET + JSP

Crear lista combinada:

```bash
cat \
  wordlists/custom/php_exts.txt \
  wordlists/custom/asp_exts.txt \
  wordlists/custom/jsp_exts.txt \
  | tr -d '\r' \
  | sed 's/#.*$//' \
  | sed '/^$/d' \
  | sort -u \
  > wordlists/generated/server_side_exts.txt
```

Generar filenames:

```bash
bin/gen_filename_wordlist.sh \
  wordlists/generated/server_side_exts.txt \
  wordlists/generated/server_side_image_evasive.txt \
  wordlists/custom/allowed_image_exts.txt
```

---

## 1.7 Allowlist no imagen: PDF, ZIP, XML, SVG

Si la aplicación permite documentos o formatos concretos:

```bash
cat > wordlists/generated/allowed_docs.txt <<'EOF'
.pdf
.docx
.xlsx
.zip
.xml
.svg
EOF

bin/gen_filename_wordlist.sh \
  wordlists/custom/php_exts.txt \
  wordlists/generated/php_docs_evasive.txt \
  wordlists/generated/allowed_docs.txt
```

Esto genera combinaciones como:

```text
shell.php.pdf
shell.pdf.php
shell.phtml.docx
shell.zip.phar
shell.svg.php
```

---

# 2. Combinar extensiones peligrosas

Script:

```bash
bin/build_extension_wordlist.sh
```

Objetivo: combinar listas custom propias en una única lista de extensiones peligrosas/interesantes.

Salida sugerida:

```text
wordlists/generated/all_dangerous_exts.txt
```

Importante:

```text
PayloadsAllTheThings no se usa como fuente para generar extensiones.
```

Su lista mezcla extensiones con payloads ya compuestos, por ejemplo `.jpg.php` o `.php%00.jpg`, y eso no encaja con este generador. Aquí queremos listas limpias de extensiones para componer nosotros el producto cartesiano.

---

# 3. Fuentes de MIME types

No hay script específico para MIME types. Normalmente basta con dos fuentes:

```text
wordlists/custom/upload_common_mime.txt
wordlists/external/seclists-all-content-types.txt
```

Uso conceptual:

| Fuente | Uso |
|---|---|
| `upload_common_mime.txt` | Lista corta y práctica |
| `seclists-all-content-types.txt` | Lista amplia desde SecLists |

---

# 4. Contenido manual para archivos

El toolkit incluye snippets en:

```text
wordlists/content/
```

La idea no es generar automáticamente archivos finales, sino tener contenido reutilizable para copiar, combinar o prefijar manualmente.

---

## 4.1 PHP

```text
wordlists/content/php/
├── php_funciona.php
├── php_introspection.php
├── phpinfo_marker.php
├── php_cmd_get.php
└── htaccess_enable_php_for_images.htaccess
```

`php_funciona.php` imprime:

```text
php_funciona
```

mediante:

```php
<?php echo base64_decode("cGhwX2Z1bmNpb25h"); ?>
```

`php_introspection.php` sirve para imprimir información del archivo ejecutado:

```text
basename_hex
file_hex
realpath_hex
script_filename_hex
document_root_hex
request_uri
```

`.htaccess` para laboratorio Apache:

```apache
AddType application/x-httpd-php .jpg .jpeg .png .gif
```

---

## 4.2 Otros lenguajes / handlers

```text
wordlists/content/aspnet/aspx_funciona.aspx
wordlists/content/jsp/jsp_funciona.jsp
wordlists/content/ssi/shtml_funciona.shtml
wordlists/content/node/ejs_funciona.ejs
```

---

# 5. Magic numbers / formatos

Firmas copiables:

```text
wordlists/content/magic_numbers/
├── common_magic_numbers.md
├── gif.txt
├── jpeg.hex
├── png.hex
├── pdf.txt
└── zip.hex
```

Estos ficheros no son payloads completos. Son referencias para copiar o prefijar contenido manualmente.

Ejemplos:

| Formato | Firma |
|---|---|
| GIF87a | `47 49 46 38 37 61` |
| GIF89a | `47 49 46 38 39 61` |
| JPEG | `FF D8 FF` |
| PNG | `89 50 4E 47 0D 0A 1A 0A` |
| PDF | `%PDF-` |
| ZIP | `50 4B 03 04` |

---

# 6. Payloads para uploads limitados

Cuando no buscas extensión ejecutable, sino impacto con tipos permitidos, usa:

```text
wordlists/content/limited_upload/
```

Organización recomendada:

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

Matriz mental:

| Tipo permitido | Ataque posible | Carpeta sugerida |
|---|---|---|
| `.html` | Stored XSS / CSRF chaining | `limited_upload/html/` |
| `.svg` | Stored XSS | `limited_upload/svg/` |
| `.svg` / `.xml` | XXE / SSRF | `limited_upload/svg/`, `limited_upload/xml/` |
| `.jpg` / `.png` | XSS en metadata | `limited_upload/metadata/` |
| `.zip` / `.tar` | Zip Slip | `limited_upload/archives/` |
| `.pdf` / `.docx` / `.xlsx` | Parser abuse / XXE ideas | `limited_upload/documents/` |
| formatos grandes | DoS controlado | `limited_upload/dos/` |

---

# 7. Convertir filenames aceptados en candidatos GET

Script:

```bash
bin/gen_get_candidates.py accepted_filenames.txt > candidates_get.txt
```

## Por qué existe

En file upload, el nombre que el servidor acepta durante la subida no siempre coincide con el nombre que después tiene sentido pedir por URL.

Ejemplo:

```text
filename aceptado: shell.jpg%00.phar
```

Si el backend guardó literalmente los caracteres `%`, `0`, `0`, entonces para pedir ese `%` por URL necesitas codificarlo como `%25`:

```text
GET candidate: shell.jpg%2500.phar
```

Este script genera variantes considerando:

```text
literal
URL-encoded
URL-decoded una vez
URL-decoded dos veces
sin caracteres de control
truncado en caracteres de control
normalización de slash/backslash
trim de espacios y puntos finales
```

Ejemplos:

| Filename aceptado | Candidatos típicos |
|---|---|
| `shell.jpg%00.phar` | `shell.jpg%2500.phar`, `shell.jpg%00.phar`, `shell.jpg.phar`, `shell.jpg` |
| `shell.phar%0a.jpg` | `shell.phar%250a.jpg`, `shell.phar%0a.jpg`, `shell.phar.jpg`, `shell.phar` |
| `shell%2ephp.jpg` | `shell%252ephp.jpg`, `shell%2ephp.jpg`, `shell.php.jpg` |

Importante:

```text
Este script no descubre rutas.
Solo transforma nombres de archivo aceptados en candidatos de URL.
```

El fuzzing de directorios o rutas de recuperación queda fuera de este toolkit.

---

# 8. Examples

La carpeta `examples/` contiene recetas concretas de generación.

Ejemplos recomendados:

```text
examples/
├── 01-php-jpg-only.md
├── 02-php-images-default.md
├── 03-custom-allowed-extensions.md
├── 04-server-side-multistack.md
├── 05-mime-sources.md
├── 06-content-snippets.md
├── 07-magic-numbers.md
├── 08-limited-upload-payloads.md
└── 09-accepted-filenames-to-get-candidates.md
```

---

# 9. Limpieza

Eliminar resultados y wordlists generadas:

```bash
bin/clean_results.sh
```

---

# Resumen rápido

| Quiero... | Uso... |
|---|---|
| Generar filenames PHP evasivos | `bin/gen_filename_wordlist.sh` |
| Usar whitelist `.jpg` propia | Tercer argumento de `gen_filename_wordlist.sh` |
| Combinar PHP + ASP.NET + JSP | Crear ext file combinado y pasarlo al generador |
| Usar MIME types | `wordlists/custom/upload_common_mime.txt` o SecLists |
| Copiar payload PHP simple | `wordlists/content/php/php_funciona.php` |
| Copiar magic bytes | `wordlists/content/magic_numbers/` |
| Preparar payloads SVG/XML/EXIF/etc. | `wordlists/content/limited_upload/` |
| Convertir aceptados a candidatos GET | `bin/gen_get_candidates.py` |
