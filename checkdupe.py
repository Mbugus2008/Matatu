import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch18.db')
c = db.cursor()
print('--- entry 12 trips ---')
for r in c.execute("SELECT Trip_No, From_Route, To_Route, sent, Dirty, Description FROM waybill_trip WHERE Weign_Bridge_id=12 ORDER BY Trip_No"):
    print(r)
