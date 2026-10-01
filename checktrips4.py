import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch13.db')
c = db.cursor()
for r in c.execute("SELECT Trip_No, Weign_Bridge_id, From_Route, To_Route, Pax_No, Total, sent FROM waybill_trip WHERE From_Route LIKE '46%' ORDER BY rowid DESC LIMIT 4"):
    print(r)
