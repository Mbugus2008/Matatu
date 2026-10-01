import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch.db')
c = db.cursor()
c.execute("DELETE FROM waybill_trip WHERE Key='SAMPLE-T-4'")
c.execute("INSERT INTO waybill_trip (Key, Weign_Bridge_id, Waybill_Key, Trip_No, From_Route, From_Time, To_Route, To_Time, Pax_No, Fare_Amount, Total, Started_By, Ended_by, Amount_Received, Expenses, Comments, sent) VALUES ('SAMPLE-T-4', 9001, 'SAMPLE-WB-1', 4, 'MOMBASA RD', 1790678400000, NULL, NULL, 0, 0.0, 0.0, 'A988', NULL, NULL, 0.0, NULL, 1)")
db.commit()
print('trips now:', list(c.execute('SELECT Key, Trip_No, To_Time, sent FROM waybill_trip')))
