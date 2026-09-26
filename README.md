# Social University

A course-based chat app for university students, built as a native iOS client with a PHP/MySQL REST backend. Students sign in, browse and join their courses, and talk with classmates in a chat room per course.

> **Status: prototype.** The core flow — sign-in, course list, enrolment and course chat — works end to end. University-email authentication is simulated in this version, and messages are delivered over the REST API rather than in real time. See [Roadmap](#roadmap).

## Features

- Sign-in flow built around the student's university email address *(verification simulated — see Roadmap)*
- Course list with filtering
- Join and leave courses
- Chat room per course with a familiar messaging-style interface
- Message history stored server-side and fetched through the API

## Architecture

```
iOS app (SwiftUI)  ──HTTPS/JSON──▶  PHP REST API  ──PDO──▶  MySQL
   │
   └── SwiftData local store
```

**iOS client**
- Swift and SwiftUI
- SwiftData for local persistence
- `URLSession`-based API layer (`APIService.swift`)

**Backend**
- PHP REST API
- MySQL, accessed through PDO with prepared statements

## API

| Method | Endpoint | Purpose |
|---|---|---|
| `POST` | `/api/login.php` | Sign in with university email |
| `GET` | `/api/courses.php` | List courses |
| `POST` | `/api/enroll.php` | Join or leave a course |
| `GET` | `/api/messages.php` | List messages for a course |
| `POST` | `/api/messages.php` | Send a message |

## Running it locally

**Backend**
1. Set up a web server with PHP and MySQL.
2. Upload the contents of `server/`.
3. Copy `config.example.php` to `config.php` and fill in your database credentials.
4. Run `schema.sql` to create the tables.

**iOS app**
1. Open `Social University.xcodeproj` in Xcode.
2. Set `baseURL` in `APIService.swift` to your server address.
3. Build and run.

## Roadmap

These are the two deliberate simplifications in the prototype and how I would replace them:

- **Real university sign-in.** Replace the simulated check with OAuth 2.0 against Microsoft Entra ID, using Microsoft Graph to confirm the account belongs to the university's tenant.
- **Real-time delivery.** Move message delivery from request/response to WebSockets, with the REST endpoint kept for history and pagination.

## License

MIT — see [`LICENSE`](LICENSE).
