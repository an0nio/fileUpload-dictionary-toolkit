# Magic numbers / file signatures

Copy these manually when you need to prepend a payload with a recognizable file signature.

## GIF

Text form:

```text
GIF87a
GIF89a
```

Hex:

```text
47 49 46 38 37 61
47 49 46 38 39 61
```

## JPEG

Hex:

```text
FF D8 FF
```

Minimal JFIF-ish prefix:

```text
FF D8 FF E0 00 10 4A 46 49 46 00
```

## PNG

Hex:

```text
89 50 4E 47 0D 0A 1A 0A
```

Escaped shell form:

```bash
printf '\x89PNG\r\n\x1a\n'
```

## PDF

Text form:

```text
%PDF-
```

Hex:

```text
25 50 44 46 2D
```

## ZIP / DOCX / XLSX / JAR

Hex:

```text
50 4B 03 04
```

Text-ish form:

```text
PK\x03\x04
```

## XML / SVG

Text form:

```xml
<?xml version="1.0"?>
<svg xmlns="http://www.w3.org/2000/svg"></svg>
```
