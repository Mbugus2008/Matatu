import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch5.db')
c = db.cursor()
c.execute("DELETE FROM Vehicle_Expenses")
c.execute("UPDATE waybill_trip SET sent=1 WHERE Key='SAMPLE-T-4'")
db.commit()
print('VE rows now:', list(c.execute('SELECT COUNT(*) FROM Vehicle_Expenses')))
print('trip sent:', list(c.execute("SELECT Key, sent FROM waybill_trip WHERE Key LIKE 'SAMPLE%'")))
