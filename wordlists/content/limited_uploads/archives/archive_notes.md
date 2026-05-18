# Archive upload notes

Usar estos paths internos para probar si el backend extrae ZIP/TAR sin normalizar rutas.

Señales:

- escritura fuera del directorio esperado
- overwrite de archivo existente
- archivo accesible fuera de la carpeta de extracción
- errores de path disclosure

No incluir zip bombs reales por defecto en el repo.
