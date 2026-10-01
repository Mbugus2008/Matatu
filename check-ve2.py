import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch4.db')
c = db.cursor()
print('== vehicle_expenses ==')
cols = [d[1] for d in c.execute('PRAGMA table_info(Vehicle_Expenses)')]
for r in c.execute('SELECT * FROM Vehicle_Expenses'):
    print(dict(zip(cols, r)))
print()
print('== waybill_trip SAMPLE-T-4 ==')
for r in c.execute("SELECT Key, Trip_No, Expenses, Comments, sent FROM waybill_trip WHERE Key='SAMPLE-T-4'"):
    print(r)
