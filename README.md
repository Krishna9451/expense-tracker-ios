# Expense Tracker (iOS + Spring Boot)

An offline-first iOS expense tracker built with **SwiftUI** and **SwiftData**, syncing to a **Spring Boot + PostgreSQL** REST API that runs in **Docker**.

![iOS CI](https://github.com/Krishna9451/expense-tracker-ios/actions/workflows/ios.yml/badge.svg)
![Backend CI](https://github.com/Krishna9451/expense-tracker-ios/actions/workflows/backend.yml/badge.svg)

## Features
- Add, edit and delete expenses; works fully offline (SwiftData)
- Filter by category and time period (last 7 days, this month)
- Spending-by-category chart (Swift Charts)
- Manual sync: pushes unsynced changes, pulls new server records
- Unit tests (XCTest, JUnit/MockMvc) and CI via GitHub Actions

## Architecture
```
SwiftUI Views ──> ExpenseViewModel (@Observable) ──> ExpenseAPI (protocol) ──> APIService (URLSession, async/await, Codable)
      │                    │                                                          │
      └── @Query ──────────┴── SwiftData (Expense model, isSynced flag)               └── REST ──> Spring Boot ──> PostgreSQL
```
- **MVVM**: views render state, the view model holds logic, `ExpenseCalculator` holds pure functions.
- **Protocol-based networking** so the sync logic is tested with a mock API.
- **Idempotent sync**: the client generates UUIDs and uses `PUT /api/expenses/{id}` (create-or-update).

## Tech stack
Swift 5, SwiftUI, SwiftData, Swift Charts, XCTest · Java 17, Spring Boot 3, Spring Data JPA, PostgreSQL, H2 (tests) · Docker, Docker Compose, GitHub Actions

## Run the backend
```bash
cd backend
docker compose up --build        # API on http://localhost:8080, Postgres on :5432
```
Without Docker: start a local Postgres with database `expenses`, then `mvn spring-boot:run`.

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/api/expenses` | List all expenses |
| POST | `/api/expenses` | Create |
| PUT | `/api/expenses/{id}` | Create or update |
| DELETE | `/api/expenses/{id}` | Delete |

## Run the iOS app (Xcode 15+, iOS 17+)
```bash
brew install xcodegen
cd ios
xcodegen generate
open ExpenseTracker.xcodeproj
```
Choose an iPhone simulator and press Run. With the backend running, tap the sync button in the top-left.

**Without XcodeGen:** in Xcode create a new iOS App named `ExpenseTracker` (SwiftUI, SwiftData off, Swift), delete the template files, drag in everything from `ios/ExpenseTracker/`, and add a unit-test target containing `ios/ExpenseTrackerTests/ExpenseTrackerTests.swift`. Add `NSAllowsLocalNetworking = YES` under App Transport Security in Info.

## Tests
```bash
# iOS: Cmd+U in Xcode, or
cd ios && xcodebuild test -project ExpenseTracker.xcodeproj -scheme ExpenseTracker \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Backend
cd backend && mvn verify
```

## Known limitations / next steps
- Items deleted while offline can reappear after the next sync (no tombstones yet)
- No authentication yet (JWT / Sign in with Apple is the next step)
- Deployment to AWS (EC2 + RDS) is not included yet



