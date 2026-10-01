import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch3.db')
c = db.cursor()
for r in c.execute("SELECT Key, Trip_No, Expenses, Comments, sent FROM waybill_trip WHERE Key LIKE 'SAMPLE%' ORDER BY Trip_No"):
    print(r)
