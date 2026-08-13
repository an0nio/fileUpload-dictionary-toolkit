# Examples

Esta carpeta contiene recetas prácticas para **generar diccionarios y preparar snippets** con `fileUpload dictionary toolkit`.

No son guías de explotación ni de uso de una herramienta concreta. El objetivo es recordar rápido:

```text
[ ] qué entrada necesita cada script
[ ] qué salida genera
[ ] cuándo tiene sentido usar cada perfil
[ ] qué variantes conviene preparar
[ ] cómo se interpreta la salida generada
```

## Cómo elegir un ejemplo

| Situación | Ejemplo recomendado |
|---|---|
| La app solo permite `.jpg` y sospechas stack PHP | `01-php-jpg-only.md` |
| La app permite imágenes comunes | `02-php-images-default.md` |
| La allowlist es propia: `.pdf`, `.zip`, `.svg`, etc. | `03-custom-allowed-extensions.md` |
| No sabes si el backend es PHP, ASP.NET o Java | `04-server-side-multistack.md` |
| Necesitas listas de `Content-Type` | `05-mime-sources.md` |
| Quieres contenido PHP/ASPX/JSP/SSI reutilizable | `06-content-snippets.md` |
| Quieres prefijar contenido con firmas de archivo | `07-magic-numbers.md` |
| El upload está limitado a HTML/SVG/XML/JPG/ZIP/etc. | `08-limited-upload-payloads.md` |
| Ya tienes filenames aceptados y quieres candidatos de URL | `09-accepted-filenames-to-get-candidates.md` |

## Filosofía

La herramienta nace de generalizar esta idea:

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

Conceptualmente:

```text
extensiones peligrosas × separadores × extensiones permitidas × patrones de filename
```

Los ejemplos muestran cómo generar esas combinaciones de forma ordenada y reutilizable, y además cómo preparar snippets para uploads limitados donde no buscas necesariamente una extensión server-side.
