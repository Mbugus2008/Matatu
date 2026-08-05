# Weigh Bridge Feature — Design Spec

> **Client**: CityHoppa  
> **Feature**: Daily vehicle weigh bridge entries with trip-level detail  
> **API**: `services.trimline.co.ke:9992/CityServices/WS/Mbranch/Page/WBridge` & `WbridgeTrip`

---

## Navigation

### Entry Points
| Entry | Location | Icon |
|-------|----------|------|
| App Drawer | `CustomDrawer` → MENU section | `Icons.scale` |
| CityHoppa Menu | `clientMenu()` | `Icons.scale` |

Both navigate to: `PageLoader(page: WBridgeListPage(), title: "Weigh Bridge")`

---

## Screens

### 1. WBridge List (`wbridge_list.dart`)

**Purpose:** Daily summary of weigh bridge entries per vehicle.

```
┌─────────────────────────────────────────┐
│  AppBar: Weigh Bridge          📅       │
├─────────────────────────────────────────┤
│  Monday, 28 Jul 2026          🔄        │
├─────────────────────────────────────────┤
│  Target: 450,000   Actual: 435,000      │
│  Shortage: 15,000                       │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ KAA 001A          [463]        ✏️    │ │
│ │ 👤 John Doe  👤 Jane Smith          │ │
│ │ Target 5000  Actual 4800  Short 200 │ │
│ │ Cash 4800            Entry #1        │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ KAB 002B          [512]        ✏️    │ │
│ │ 👤 Mike K.   👤 Sarah W.            │ │
│ │ Target 4500  Actual 4500  Short 0   │ │
│ │ Cash 4500            Entry #2        │ │
│ └─────────────────────────────────────┘ │
│                                         │
│              [+ New Entry]              │
└─────────────────────────────────────────┘
```

**Interactions:**
- Tap card → opens **Trip List** for that weigh bridge
- Tap ✏️ → opens **WBridge Form** (edit mode)
- Tap 📅 → date picker
- Tap 🔄 → refresh from API
- Tap [+ New Entry] → opens **WBridge Form** (create mode)

**Summary bar:**
- Total Target Revenue (all entries)
- Total Actual Revenue (all entries)
- Total Shortage (Σ target − actual)

---

### 2. WBridge Form (`wbridge_form.dart`)

**Purpose:** Create or edit a weigh bridge entry.

```
┌─────────────────────────────────────────┐
│  AppBar: New Weigh Bridge               │
├─────────────────────────────────────────┤
│  ── Vehicle ────────────────────────────│
│  Fleet No * (search)  │  Vehicle No     │
│  ┌──────────────────┐ │ ┌────────────┐  │
│  │ KAA 001A (F463)  │ │ │ KAA 001A   │  │
│  │ KAB 002B (F512)  │ │ │  (disabled) │  │
│  └──────────────────┘ │ └────────────┘  │
│                                         │
│  ── Crew ───────────────────────────────│
│  Driver              │  Conductor       │
│  [John Doe]          │  [Jane Smith]    │
│                                         │
│  ── Date & Time ────────────────────────│
│  Date *              │                  │
│  [28 Jul 2026    📅] │                  │
│  Start Time          │  Finish Time     │
│  [10:23 AM      🕐]  │  [6:00 PM   🕐]  │
│                                         │
│  ── Revenue ────────────────────────────│
│  Target Revenue *    │  Actual Revenue  │
│  [5000]              │  [4800]          │
│                                         │
│  ┌─ Shortage: 200.00 ──────────────┐   │
│  └──────────────────────────────────┘   │
│                                         │
│  Cash                                    │
│  [4800]                                  │
│                                         │
│  ┌──────────────────────────────────┐   │
│  │            💾  Save              │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

**Auto-fill on Fleet selection:**
| Field | Source |
|-------|--------|
| `Vehicle_No` | `Vehicles.Vehicle_Number` |
| `Target_Revenue` | `Vehicles.Daily_Contribution` |
| `Driver` | `vehicle_crew` table → `Crew_type.Driver` → `Crew_Name` |
| `Conductor` | `vehicle_crew` table → `Crew_type.Conductor` → `Crew_Name` |

**Defaults:**
- `Start_Time` = `TimeOfDay.now()` (creation time)
- `Date` = today
- `Finish_Time` = 6:00 PM

**Validation:** Fleet No required. Shortage auto-calculated on change.

**Persistence:** Saves to local SQLite (`sent=0`), syncs to API in background.

---

### 3. Trip List (`trip_list.dart`)

**Purpose:** View all trips for a selected weigh bridge entry.

```
┌─────────────────────────────────────────┐
│  AppBar: Trips — KAA 001A               │
├─────────────────────────────────────────┤
│  KAA 001A — F463                        │
│  Driver: John Doe | Cond: Jane Smith     │
│  Target: 5,000        Actual: 4,800     │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ ┌──────┐  Nairobi → Mombasa    ✏️   │ │
│ │ │Trip#1│  08:00 — 14:00             │ │
│ │ └──────┘                            │ │
│ │ ─────────────────────────────────── │ │
│ │  👥 32    💰 500   📄 16,000  💸 2K │ │
│ │  💬 "Morning run, light traffic"    │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ ┌──────┐  Mombasa → Nairobi    ✏️   │ │
│ │ │Trip#2│  15:00 — 21:00             │ │
│ │ └──────┘                            │ │
│ │ ─────────────────────────────────── │ │
│ │  👥 28    💰 500   📄 14,000  💸 1K │ │
│ └─────────────────────────────────────┘ │
│                                         │
│              [+ Add Trip]               │
└─────────────────────────────────────────┘
```

**Stats per trip card:**
- 👥 Pax count
- 💰 Fare amount per passenger
- 📄 Total (pax × fare)
- 💸 Expenses

---

### 4. Trip Form (`trip_form.dart`)

**Purpose:** Add or edit a trip within a weigh bridge entry.

```
┌─────────────────────────────────────────┐
│  AppBar: New Trip                       │
├─────────────────────────────────────────┤
│  ── Route ──────────────────────────────│
│  From *              │  To *            │
│  [Nairobi]           │  [Mombasa]       │
│  Departure           │  Arrival         │
│  [08:00 AM     🕐]   │  [2:00 PM   🕐]  │
│                                         │
│  ── Passenger & Fare ───────────────────│
│  Passengers *        │  Fare Amount *   │
│  [32]                │  [500]           │
│                                         │
│  ┌─ Total: 16,000.00 ──────────────┐   │
│  └──────────────────────────────────┘   │
│                                         │
│  ── Other Details ──────────────────────│
│  Started By                             │
│  [Agent A]                              │
│  Amount Received                        │
│  [CASH]                                 │
│  Expenses                               │
│  [2000]                                 │
│  Comments                               │
│  [Test trip                    ]        │
│                                         │
│  ┌──────────────────────────────────┐   │
│  │          💾  Save Trip           │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

**Auto-calc:** Total = Passengers × Fare Amount (on change).

---

## Data Models

### WBridge
| Field | Type | Description |
|-------|------|-------------|
| `Key` | `String?` | Primary key (auto-generated if new) |
| `Vehicle_No` | `String?` | Vehicle registration |
| `Fleet_No` | `String?` | Fleet identifier |
| `Driver` | `String?` | Driver name |
| `Conductor` | `String?` | Conductor name |
| `Date` | `DateTime?` | Entry date |
| `Start_Time` | `DateTime?` | Shift start |
| `Finish_Time` | `DateTime?` | Shift end |
| `Target_Revenue` | `double?` | Expected revenue |
| `Actual_Revenue` | `double?` | Actual collected |
| `Shortage` | `double?` | Target − Actual |
| `Entry_No` | `int?` | Server-assigned entry number |
| `Cash` | `double?` | Cash collected |
| `Total_Expected` | `double?` | Server-calculated |
| `Total_Collected` | `double?` | Server-calculated |
| `sent` | `bool` | Sync status (local DB) |

### WbridgeTrip
| Field | Type | Description |
|-------|------|-------------|
| `Key` | `String?` | Primary key |
| `Weign_Bridge_id` | `int?` | Parent weigh bridge entry |
| `Trip_No` | `int?` | Trip number |
| `From` | `String?` | Origin |
| `From_Time` | `DateTime?` | Departure time |
| `To` | `String?` | Destination |
| `To_Time` | `DateTime?` | Arrival time |
| `Pax_No` | `int?` | Passenger count |
| `Fare_Amount` | `double?` | Fare per passenger |
| `Total` | `double?` | Pax × Fare |
| `Started_By` | `String?` | Agent who started |
| `Ended_by` | `String?` | Agent who ended |
| `Amount_Received` | `String?` | Payment method |
| `Expenses` | `double?` | Trip expenses |
| `Comments` | `String?` | Notes |

---

## API Endpoints

| Method | Route | Purpose |
|--------|-------|---------|
| POST | `api/Transactions/wbridges` | List WBridge entries (date + optional vehicle) |
| POST | `api/Transactions/addwbridge` | Create/update WBridge entry |
| POST | `api/Transactions/wbridgetrips` | List trips for a weigh bridge ID |
| POST | `api/Transactions/addwbridgetrip` | Create/update trip |

---

## Offline-First Flow

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│  Save    │ ──▶ │ Local DB │ ──▶ │  API     │
│  Form    │     │ (sent=0) │     │ (bg sync)│
└──────────┘     └──────────┘     └──────────┘
                       │                │
                       │ fail           │ success
                       ▼                ▼
                  stays pending    mark sent=1
                        │
                  upload() picks
                  up all unsent
```

---

## Files

```
lib/
├── models/weighbridge/
│   └── wbridge.dart            # Models + WBridgeService
├── controllers/
│   └── wbridge_controller.dart # GetX controller
├── pages/weighbridge/
│   ├── wbridge_list.dart       # Main list screen
│   ├── wbridge_form.dart       # Entry form (autocomplete + auto-fill)
│   ├── trip_list.dart          # Trip list for entry
│   └── trip_form.dart          # Trip form
├── providers/
│   ├── db.dart                 # + WBridge.createtable
│   └── clients/Citihoppa.dart  # + WBridgeController init + menu
├── pages/setting.dart          # + Drawer entry
└── init.dart                   # + syncPendingWBridges() in upload()
```
