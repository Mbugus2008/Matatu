import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-verify.db')
c = db.cursor()
print('verify trips:', list(c.execute("SELECT Key, sent FROM waybill_trip")))
print('verify routes:', list(c.execute("SELECT COUNT(*) FROM routes"))[0][0])
