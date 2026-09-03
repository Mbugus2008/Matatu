# Add / Edit Hire — Page Design (`lib/pages/hires/addhire.dart`)

## Purpose
Create a new hire record or edit an existing one. Used for both modes via `AddHireScreen(hire: Hires?)` — `null` = create, non-null = edit.

## Screen structure (top → bottom)

```
Scaffold (background #F4F6F9 light grey)
├── AppBar (green #006B3F, centerTitle, height 44)
│     Title: "Add New Hire" | "Edit Hire"
├── Body: Stack
│   ├── Form (SingleChildScrollView, bottom padding 90 for button)
│   │   └── White rounded card (radius 12, soft shadow blur 10 / offset (0,3) / 6% black)
│   │       └── Column (sections)
│   └── Positioned (bottom, left/right 16) → Submit button (shadow)
```

## Sections & widgets

| Section | Widgets |
|---------|---------|
| **Vehicle Information** | `VehicleNumberInput` — Autocomplete (fleet no + vehicle no + type suggestions), fills vehicle + fleet controllers on pick. Required. |
| **Hire Period** | Row: `DateInput` Start Date + Return Date · Row: `TimeInput` Start Time + Return Time (read-only fields, open date/time pickers on tap) |
| **Client Information** | `CustomDropdown<client>` Client Type * (Corporate/Private) + `TextInput` Client Name · `TextInput` In Charge · `TextInput` Department · `TextInput` Destination |
| **Hire Details** | Amount `TextFormField` (Kshs prefix, 2-decimal formatter, errorText when empty) · `CustomDropdown<hire_Type>` Hire Type * (None/Dropoff/Pick and Drop/Full Day/Half Day) · `CustomDropdown<vat_Type>` VAT · `CustomDropdown<payment_Methods>` Payment Method (Cash/Bank/Paybill) |

## Theme
- Primary green `#006B3F` (app bar, section headers, submit button, focused input borders).
- Inputs: white fill, rounded 8, red border when empty, green focus border (1.5px).
- Required hint texts in red 12px below empty required fields.
- Section headers: 16px w600 green.

## Submit button states
- Idle: green, full width, label **CREATE HIRE** / **UPDATE HIRE**.
- Saving (`saving` RxBool): disabled, keeps green, spinner + **UPDATING...**, prevents double taps.

## Validation (client-side, in order)
1. Vehicle required → snackbar "Please select a vehicle"
2. Client type required → "Please select a client type"
3. Amount required → "Please enter an amount"
4. Hire type required → "Please select a hire type"
5. VAT type required → "Please select a Vat Type"
6. Payment method required → "Please select a Payment Method"
7. All field texts non-empty else "Please fill in all fields"
8. Amount parses to double else "Please enter a valid amount"
9. Return date/time must be today or future else "Return date and time must be in the future"

## Save flow (`_submitForm`)
1. Validate → build `Hires` (vehicle, amount, dates/times, client, hire type, VAT, payment, fleet, destination, client name, in charge, department, driver, created by agent code).
2. `saving = true` → `await Hires().savetires(newHire)` → `saving = false`.
3. `savetires`: local SQLite insert → `POST addHires` (await) → on `Code == 0` re-insert returned record.
4. `Get.back()` + "New hire added successfully" snackbar.

## Notes / known gaps
- `parseTime` expects `h:mm a` while `TimeInput` writes `HH:mm` — unify before relying on times.
- Edit mode: `_submitForm` builds a fresh `Hires` — the original `Key`/`Code` must be carried over, otherwise the server `Read(Code)` lookup fails and creates a duplicate instead of updating.
