import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch15.db')
c = db.cursor()
print('--- entry 12 trips (local) ---')
for r in c.execute("SELECT Trip_No, From_Route, To_Route, Pax_No, Total, sent FROM waybill_trip WHERE Weign_Bridge_id=12 ORDER BY Trip_No"):
    print(r)
