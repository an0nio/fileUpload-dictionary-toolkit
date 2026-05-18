# Safe DoS-oriented upload tests

No incluir payloads destructivos por defecto.

Pruebas seguras:

- archivo vacío
- archivo de 1 byte
- archivo justo por debajo del límite
- archivo justo por encima del límite
- imagen con dimensiones grandes pero tamaño moderado en entorno controlado
- ZIP pequeño con varios niveles de carpetas, sin bomb real

Señales:

- timeout
- error 500
- worker crash
- consumo anómalo
- lentitud al generar thumbnails
- rechazo por límites de tamaño

Controles defensivos a revisar:

- límite de tamaño comprimido
- límite de tamaño descomprimido
- límite de dimensiones
- límite de número de archivos
- timeout de procesamiento
- sandbox de parsers
