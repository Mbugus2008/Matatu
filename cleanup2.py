import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch7.db')
c = db.cursor()
c.execute("DELETE FROM waybill_trip WHERE Key='SAMPLE-T-5'")
c.execute("UPDATE waybill_trip SET sent=1 WHERE Key='SAMPLE-T-4'")
c.execute("DELETE FROM routes WHERE Key='LOCAL-ROUTE-1'")
db.commit()
print('trips:', list(c.execute("SELECT Key, sent FROM waybill_trip")))
print('routes count:', list(c.execute("SELECT COUNT(*) FROM routes"))[0][0])
