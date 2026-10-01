import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch12.db')
c = db.cursor()
print('--- vehicle_expenses latest ---')
cols = [r[1] for r in c.execute("PRAGMA table_info(Vehicle_Expenses)")]
print('cols:', cols)
for r in c.execute("SELECT * FROM Vehicle_Expenses ORDER BY rowid DESC LIMIT 3"):
    print(r)
print('--- trip expenses field ---')
for r in c.execute("SELECT Trip_No, From_Route, To_Route, Expenses, Comments, sent FROM waybill_trip WHERE Weign_Bridge_id=12"):
    print(r)
