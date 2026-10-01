import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch11.db')
c = db.cursor()
print('--- latest trips ---')
for r in c.execute("SELECT Key, Weign_Bridge_id, Trip_No, Fromx, To_, Pax_No, Fare_Amount, Total, sent FROM waybill_trip ORDER BY rowid DESC LIMIT 4"):
    print(r)
print('--- entries today ---')
for r in c.execute("SELECT Entry_No, Vehicle_No, Fleet_No, Target_Revenue, sent, Key FROM waybill WHERE DateX LIKE '%2026-09-29%' OR DATE(DateX/1000,'unixepoch')='2026-09-29' LIMIT 8"):
    print(r)
