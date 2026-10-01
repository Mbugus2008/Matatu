import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch14.db')
c = db.cursor()
print('--- new vehicle expenses (latest 4) ---')
for r in c.execute("SELECT Code, Vehicle_No, Description, Amount, Fleet_No, sent FROM Vehicle_Expenses ORDER BY rowid DESC LIMIT 4"):
    print(r)
print('--- trips entry 11/12 ---')
for r in c.execute("SELECT Weign_Bridge_id, Trip_No, Expenses, Comments, sent FROM waybill_trip WHERE Weign_Bridge_id IN (11,12)"):
    print(r)
