class DbUpdate {
  final int version;
  final List<String> updates;

  DbUpdate({
    required this.version,
    required List<String> updates,
  }) : updates = List.unmodifiable(updates);
}

class DbUpdatesCatalog {
  DbUpdatesCatalog._();

  static final Map<String, List<DbUpdate>> _updatesByTable =
      Map.unmodifiable(<String, List<DbUpdate>>{
    'Members': [
      DbUpdate(version: 1, updates: <String>[
        'ALTER TABLE Members ADD COLUMN Crew_Type int ',
        'ALTER TABLE Members ADD COLUMN Loans float ',
        'ALTER TABLE Members ADD COLUMN Vehicle text',
      ]),
    ],
    'TranTypes': [
      DbUpdate(version: 2, updates: <String>[
        'ALTER TABLE TranTypes ADD COLUMN Amount float ',
      ]),
      DbUpdate(version: 3, updates: <String>[
        'ALTER TABLE TranTypes ADD COLUMN Customer_Posting_Group text ',
      ]),
    ],
    'Header': [
      DbUpdate(version: 4, updates: <String>[
        'ALTER TABLE Header ADD COLUMN Customer_Posting_Group text ',
        'ALTER TABLE Header ADD COLUMN Crew text',
        'ALTER TABLE Header ADD COLUMN Crew2 text',
      ]),
      DbUpdate(version: 5, updates: <String>[
        'ALTER TABLE Header ADD COLUMN Fleet text ',
      ]),
      DbUpdate(version: 30, updates: <String>[
        'ALTER TABLE Header ADD COLUMN Comments text ',
      ]),
    ],
    'vehicles': [
      DbUpdate(version: 3, updates: const <String>[]),
    ],
    'TAmounts': [
      DbUpdate(version: 6, updates: <String>[
        '''create table IF NOT EXISTS TAmounts (
Key  text,
Code text  ,
Vehicle_Type  int,
Amount  float,
Name  text,
PRIMARY KEY (Code, Vehicle_Type)

 )''',
      ]),
    ],
    'Reversals': [
      DbUpdate(version: 11, updates: <String>[
        '''create table IF NOT EXISTS Reversals (
    Key text,
    Receipt_No text Not Null  ,
    Date int,
    Status int,
    Created_By text Not Null,
    Total_Amount float,
    Total_Trans int,
    Transction_Date int,
    Agent text,
    Reason_for_Reversal text,
    Vehicle text,
    Account text,
    Name text,
    Sent bit,
     PRIMARY KEY (Receipt_No,  Created_By)
 )''',
      ]),
    ],
    'Expenses': [
      DbUpdate(version: 7, updates: <String>[
        '''create table IF NOT EXISTS Expenses (
Key  text,
Code text primary key ,
Description  text


 )''',
      ]),
    ],
    'Hires': [
      DbUpdate(version: 14, updates: <String>[
        '''create table IF NOT EXISTS Hires (
Key  text,
Vehicle_No text,
Code text primary key,
Start_Date  text,
Start_Time  text,
Return_Date  text,
Return_Time  text,
Amount  float,
Client  int,
Hire_Type  int,
Vat_Type  int,
Payment_Methods  int,
Entry  int,
    Created_by  text,
Fleet_No  text,
Destination  text,
Client_Name  text,
Incharge  text,
Department  text,
Driver  text

 )''',
      ]),
      DbUpdate(version: 15, updates: <String>[
        'ALTER TABLE Hires ADD COLUMN Fleet_No text ',
      ]),
      DbUpdate(version: 16, updates: <String>[
        'ALTER TABLE Hires ADD COLUMN Destination text ',
        'ALTER TABLE Hires ADD COLUMN Client_Name text ',
        'ALTER TABLE Hires ADD COLUMN Incharge text ',
        'ALTER TABLE Hires ADD COLUMN Department text ',
        'ALTER TABLE Hires ADD COLUMN Driver text ',
      ]),
    ],
    'bus_inspections': [
      DbUpdate(version: 18, updates: <String>[
        '''    CREATE TABLE IF NOT EXISTS bus_inspections (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bus_identifier TEXT NOT NULL,
      inspector_name TEXT,
      inspection_date TEXT NOT NULL,
      fields_json TEXT NOT NULL,
      is_synced INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )''',
      ]),
    ],
  });

  static List<DbUpdate> forTable(String table) {
    final List<DbUpdate>? entries = _updatesByTable[table];
    if (entries == null) {
      return <DbUpdate>[];
    }
    return entries
        .map((DbUpdate entry) => DbUpdate(
              version: entry.version,
              updates: entry.updates,
            ))
        .toList(growable: false);
  }
}

List<DbUpdate> getDbUpdatesForTable(String table) {
  return DbUpdatesCatalog.forTable(table);
}
