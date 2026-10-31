# gestor_cafeteria

Cliente Flutter de una cafetería que consume la API de pedidos de [mini_backend](https://github.com/DMI-2026/mini_backend). Proyecto de la asignatura Desarrollo Móvil Integral (10.º A, septiembre–diciembre 2026).

En esta versión (`v0.1.0`) el proyecto contiene el cliente HTTP (`ApiClient`), que traduce cada respuesta no exitosa del servidor a un `Failure` tipado, y sus pruebas automatizadas con `MockClient`. La pantalla de `main.dart` solo muestra la lista de pedidos para comprobar la conexión.

| Respuesta del servidor          | Failure que lanza `ApiClient`                      |
|---------------------------------|----------------------------------------------------|
| 200–299                         | Ninguno: devuelve el JSON decodificado             |
| 404                             | `NotFoundFailure` con el texto de `detail`         |
| 409                             | `ConflictFailure` con el texto de `detail`         |
| 422                             | `ValidationFailure` con `fields` (`loc[1]` → `msg`) |
| 500–599                         | `ServerFailure` con el código de estado            |
| Cualquier otro código (p. ej. 300, 418) | `UnexpectedFailure` con el código y el `detail` |
| Sin conexión o tiempo agotado   | `NetworkFailure`                                   |

## Requisitos

- Flutter 3.47 o superior (Dart 3.13). Probado con Flutter 3.47.2.
- Node.js 22.13 o superior para el servidor (`node --version`). Probado con Node 24.15.0.
- Chrome, un emulador de Android o un celular para ejecutar la app.

## Servidor: mini_backend

`mini_backend` es **otro repositorio** y no se copia dentro de este proyecto:

- Repositorio: https://github.com/DMI-2026/mini_backend (rama `master`)
- Versión con la que se probó: commit [`94d2533`](https://github.com/DMI-2026/mini_backend/commit/94d2533) («feat: enable CORS for Flutter web clients»), `package.json` versión `0.1.0`.

Para levantarlo (no necesita `npm install`, solo usa módulos integrados de Node):

```bash
git clone https://github.com/DMI-2026/mini_backend.git
cd mini_backend
node server.js        # Listening on http://0.0.0.0:8000
```

Comprueba en el navegador `http://localhost:8000/health`: debe responder `{"status":"ok"}`. Para correr las pruebas del servidor usa `node --test`.

## Ejecutar la app

Con el servidor encendido, desde la carpeta de este proyecto:

```bash
flutter pub get
flutter run -d chrome
```

La URL del servidor se toma de `API_URL`. Si no se indica, se usa `http://localhost:8000` en web y `http://10.0.2.2:8000` en el emulador de Android (la dirección del equipo anfitrión). En un celular físico, en la misma red que la computadora:

```bash
flutter run --dart-define=API_URL=http://<IP de tu computadora>:8000
```

No hace falta el perfil «Chrome sin CORS» de `.vscode/launch.json`: el servidor ya permite CORS.

## Pruebas

```bash
flutter analyze   # debe terminar en "No issues found!"
flutter test      # 15 pruebas en verde
```

Las pruebas no usan la red ni el servidor real:

- `test/core/failure_test.dart`: la jerarquía de `Failure` y su `switch` exhaustivo.
- `test/core/http_client_test.dart`: `ApiClient` con un `MockClient` que simula 200, 404, 409, 422, 503, 300, falta de conexión y tiempo agotado.

## Estructura

```
lib/
  core/
    failure.dart       # sealed class Failure y sus subtipos
    http_client.dart   # ApiClient: GET/POST/PATCH/DELETE y mapeo de errores
  main.dart            # pantalla de prueba que lista /orders
test/
  core/                # pruebas de failure.dart y http_client.dart
android/, web/         # plataformas generadas por Flutter
```
