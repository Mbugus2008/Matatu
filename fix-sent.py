import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch3.db')
c = db.cursor()
c.execute("UPDATE waybill_trip SET sent=1 WHERE Key='SAMPLE-T-4'")
db.commit()
print('updated:', list(c.execute("SELECT Key, sent FROM waybill_trip WHERE Key LIKE 'SAMPLE%'")))
