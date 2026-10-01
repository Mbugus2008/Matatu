import sqlite3, datetime
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch10.db')
c = db.cursor()
def ts(v):
    try:
        return datetime.datetime.fromtimestamp(int(v)/1000).strftime('%m-%d %H:%M')
    except Exception:
        return v
print('== wbill (latest 6) ==')
for r in c.execute("SELECT Entry_No, Vehicle_No, Fleet_No, Date, Target_Revenue, sent, Key FROM wbill ORDER BY rowid DESC LIMIT 6"):
    print(r[0], r[1], r[2], ts(r[3]), 'target', r[4], 'sent', r[5], r[6])
print('== trips (latest 8) ==')
for r in c.execute("SELECT Weign_Bridge_id, Trip_No, From_Route, To_Route, Pax_No, Fare_Amount, To_Time, sent FROM waybill_trip ORDER BY rowid DESC LIMIT 8"):
    print(r[0], 'trip', r[1], r[2], '->', r[3], 'pax', r[4], 'fare', r[5], 'open' if r[6] is None else 'closed '+ts(r[6]), 'sent', r[7])
print('== Vehicle_Expenses (latest 5) ==')
for r in c.execute("SELECT Vehicle_No, Date, Description, Amount, Created_By, sent FROM Vehicle_Expenses ORDER BY rowid DESC LIMIT 5"):
    print(r[0], ts(r[1]), r[2], r[3], r[4], 'sent', r[5])
print('== SAMPLE vehicles ==')
for r in c.execute("SELECT Vehicle_Number, Fleet_No, Vehicle_Type, Daily_Contribution FROM vehicles WHERE Vehicle_Number LIKE '%SAMPLE%' OR Fleet_No='999' LIMIT 8"):
    print(r)
print('== crew for SAMPLE-T-4 ==')
for r in c.execute("SELECT No, Name, Crew_Type, Vehicle FROM Members WHERE Vehicle LIKE '%SAMPLE%' OR Vehicle LIKE '%T-4%' LIMIT 10"):
    print(r)
