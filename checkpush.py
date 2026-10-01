import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch19.db')
c = db.cursor()
for r in c.execute("SELECT Trip_No, Fare_Amount, Total, sent, Dirty FROM waybill_trip WHERE Weign_Bridge_id=12 AND Trip_No=2"):
    print('local trip2:', r)
