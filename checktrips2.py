import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch11.db')
c = db.cursor()
print('trip cols:', [r[1] for r in c.execute("PRAGMA table_info(waybill_trip)")])
print('wb cols:', [r[1] for r in c.execute("PRAGMA table_info(waybill)")])
