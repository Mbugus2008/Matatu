import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch10.db')
c = db.cursor()
print('== today waybills ==')
for r in c.execute("SELECT Entry_No, Vehicle_No, Fleet_No, Date, Driver, Conductor, Target_Revenue, sent, Key FROM waybill WHERE Date >= 1780000000000 OR Date IS NULL ORDER BY Entry_No DESC LIMIT 6"):
    print(r)
print('== trips (last 8) ==')
for r in c.execute("SELECT Weign_Bridge_id, Trip_No, From, To, Pax_No, Fare_Amount, To_Time IS NULL as open, sent, Key FROM waybill_trip ORDER BY rowid DESC LIMIT 8"):
    print(r)
print('== vehicle_expenses (last 5) ==')
for r in c.execute("SELECT rowid, Vehicle_No, Date, Description, Amount, Created_By, sent FROM vehicle_expenses ORDER BY rowid DESC LIMIT 5"):
    print(r)
print('== SAMPLE vehicles ==')
for r in c.execute("SELECT Vehicle_Number, Fleet_No, Vehicle_Type, Daily_Contribution FROM vehicles WHERE Vehicle_Number LIKE '%SAMPLE%' OR Fleet_No='999'"):
    print(r)
