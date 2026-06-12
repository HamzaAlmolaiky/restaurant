# Restaurant

Flutter restaurant management application built with GetX and SQLite.

## Supported Targets

- Windows, Linux, and macOS use `sqflite_common_ffi`.
- Android and iOS use the regular `sqflite` database factory.

Web is not configured because the application depends on local SQLite and file
system APIs.

## Getting Started

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

Use another device id when targeting Android, iOS, Linux, or macOS.

## Database

The bundled database is stored at:

```text
assets/db/RestaurantDB.db
```

On first launch it is copied to the application documents directory. Schema
checks run when the database opens, and applied schema versions are recorded in
`Schema_Migrations`.

## Authentication

New and changed passwords are stored as hashes. Legacy plain-text passwords are
accepted only for migration compatibility and are upgraded to a hash after a
successful login.

## Tests

Current test coverage starts with password hashing behavior:

```bash
flutter test
```

Add service-level database tests before changing order, payment, shift, or
return flows.
