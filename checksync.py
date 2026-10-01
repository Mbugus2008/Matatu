import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch16.db')
c = db.cursor()
print('--- trips today (entry 11/12) ---')
for r in c.execute("SELECT Weign_Bridge_id, Trip_No, From_Route, sent FROM waybill_trip WHERE Weign_Bridge_id IN (11,12) ORDER BY Weign_Bridge_id, Trip_No"):
    print(r)
print('--- waybills sent flags ---')
for r in c.execute("SELECT Entry_No, Vehicle_No, sent FROM wbill WHERE Entry_No IN (11,12)"):
    print(r)
print('--- vehicle expenses sent flags ---')
for r in c.execute("SELECT Code, Description, Amount, Fleet_No, sent FROM Vehicle_Expenses ORDER BY rowid DESC LIMIT 6"):
    print(r)
