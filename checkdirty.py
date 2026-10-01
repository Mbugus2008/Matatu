import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch17.db')
c = db.cursor()
print('--- entry 12 trips ---')
for r in c.execute("SELECT Trip_No, From_Route, To_Route, From_Time, To_Time, sent, Dirty, Description FROM waybill_trip WHERE Weign_Bridge_id=12 ORDER BY Trip_No"):
    print(r)
print('--- dirty rows anywhere ---')
for r in c.execute("SELECT Weign_Bridge_id, Trip_No, Dirty, sent FROM waybill_trip WHERE Dirty=1"):
    print(r)
