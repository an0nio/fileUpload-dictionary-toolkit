# 09 - Convertir filenames aceptados en candidatos GET

## Objetivo

Transformar una lista de filenames que fueron aceptados durante el upload en variantes razonables para pedir esos nombres por URL.

Este ejemplo no descubre rutas. Solo transforma nombres.

```text
accepted filenames → URL filename candidates
```

---

## Por qué existe

En file upload, el nombre usado en `filename="..."` puede sufrir distintos tratamientos:

```text
[ ] guardado literal
[ ] URL-decode una vez
[ ] URL-decode dos veces
[ ] eliminación de caracteres de control
[ ] truncado en %00, %0a, %0d, tab, etc.
[ ] trim de espacios/puntos finales
[ ] normalización de slash/backslash
```

Por eso, si un upload aceptó:

```text
shell.jpg%00.phar
```

quizá el recurso accesible tenga que pedirse como:

```text
shell.jpg%2500.phar
```

porque en URL:

```text
%25 = %
```

---

## Entrada esperada

Un fichero plano con un filename aceptado por línea:

```text
results/accepted_filenames.txt
```

Ejemplo:

```text
shell.jpg%00.phar
shell.phar%0a.jpg
shell%2ephp.jpg
shell.phtml%20.jpg
shell.php/.jpg
```

Crear entrada de ejemplo:

```bash
cd /opt/fileUpload
cat > results/accepted_filenames.txt <<'EOF_ACCEPTED'
shell.jpg%00.phar
shell.phar%0a.jpg
shell%2ephp.jpg
shell.phtml%20.jpg
shell.php/.jpg
EOF_ACCEPTED
```

---

## Generar candidatos

```bash
bin/gen_get_candidates.py \
  results/accepted_filenames.txt \
  > results/candidates_get.txt
```

Salida:

```text
results/candidates_get.txt
```

Comprobaciones:

```bash
wc -l results/candidates_get.txt
sort results/candidates_get.txt | head -50
```

Buscar familias concretas:

```bash
grep -E '%2500|%250a|%252e|%2520' results/candidates_get.txt
```

---

## Ejemplos de conversión

| Filename aceptado | Candidatos típicos |
|---|---|
| `shell.jpg%00.phar` | `shell.jpg%2500.phar`, `shell.jpg%00.phar`, `shell.jpg.phar`, `shell.jpg` |
| `shell.phar%0a.jpg` | `shell.phar%250a.jpg`, `shell.phar%0a.jpg`, `shell.phar.jpg`, `shell.phar` |
| `shell%2ephp.jpg` | `shell%252ephp.jpg`, `shell%2ephp.jpg`, `shell.php.jpg` |
| `shell.phtml%20.jpg` | `shell.phtml%2520.jpg`, `shell.phtml%20.jpg`, `shell.phtml.jpg`, `shell.phtml` |
| `shell.php/.jpg` | `shell.php/.jpg`, `shell.php.jpg`, `shell.php` |

---

## Qué familias genera el script

| Familia | Para qué sirve |
|---|---|
| Original | La ruta acepta el string como llegó |
| `%` escapado como `%25` | El backend guardó `%XX` literalmente |
| Decodificado una vez | El backend aplicó URL-decode |
| Decodificado dos veces | Caso de doble decoding |
| Sin control chars | El backend eliminó caracteres problemáticos |
| Truncado | El backend cortó en NUL/newline/tab |
| Trim | El backend quitó espacios o puntos finales |
| Slash/backslash normalizado | Diferencias Linux/Windows/router |

---

# Casos típicos

## `%00`

```text
accepted:          shell.jpg%00.phar
candidate literal: shell.jpg%2500.phar
candidate decoded: shell.jpg%00.phar
candidate sanitized: shell.jpg.phar
candidate truncated: shell.jpg
```

## `%0a`

```text
accepted:          shell.phar%0a.jpg
candidate literal: shell.phar%250a.jpg
candidate decoded: shell.phar%0a.jpg
candidate sanitized: shell.phar.jpg
candidate truncated: shell.phar
```

## `%2e`

```text
accepted:          shell%2ephp.jpg
candidate literal: shell%252ephp.jpg
candidate decoded: shell.php.jpg
```

## `%20`

```text
accepted:          shell.phtml%20.jpg
candidate literal: shell.phtml%2520.jpg
candidate decoded: shell.phtml%20.jpg
candidate sanitized: shell.phtml.jpg
candidate trimmed: shell.phtml
```

---

## Importante

Este script no sabe:

```text
[ ] en qué directorio se guardó el archivo
[ ] si el archivo es público
[ ] si el servidor lo ejecuta
[ ] si necesita autenticación
```

Solo ayuda a no perder tiempo convirtiendo manualmente nombres raros a candidatos de URL.

El fuzzing de directorios/rutas de recuperación queda fuera del alcance de este toolkit.

---

## Cuándo usarlo

```text
[ ] Ya tienes una lista de filenames aceptados.
[ ] Esos filenames contienen %00, %0a, %20, %2e, /, \, puntos finales o similares.
[ ] Quieres probar variantes de URL sin hacer conversiones manuales.
```

## Cuándo no usarlo

```text
[ ] Todavía no tienes filenames aceptados.
[ ] Lo que necesitas es descubrir directorios.
[ ] El backend renombra todo a UUID/hash y ya te da el nombre final.
```
