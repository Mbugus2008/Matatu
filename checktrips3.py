import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch11.db')
c = db.cursor()
print('tables:', [r[0] for r in c.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")][:40])
print('--- latest trips ---')
for r in c.execute("SELECT Trip_No, Weign_Bridge_id, From_Route, To_Route, Pax_No, Fare_Amount, Total, sent, Comments FROM waybill_trip ORDER BY rowid DESC LIMIT 5"):
    print(r)
