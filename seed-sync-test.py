import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch6.db')
c = db.cursor()
# local route so a long description can resolve to its code
c.execute("DELETE FROM routes WHERE Key='LOCAL-ROUTE-1'")
c.execute("INSERT INTO routes (Key, Code, Description, sent) VALUES ('LOCAL-ROUTE-1','UPDATEDROUTENAIROBA','Updated Route - Nairobi Express',1)")
# pending trip with a long route that has a local match -> expect the CODE
c.execute("UPDATE waybill_trip SET From_Route='Updated Route - Nairobi Express', sent=0 WHERE Key='SAMPLE-T-4'")
# pending trip with long text and NO route -> expect trimming to 20 chars
c.execute("DELETE FROM waybill_trip WHERE Key='SAMPLE-T-5'")
c.execute("INSERT INTO waybill_trip (Key, Weign_Bridge_id, Waybill_Key, Trip_No, From_Route, From_Time, To_Route, To_Time, Pax_No, Fare_Amount, Total, Started_By, Ended_by, Amount_Received, Expenses, Comments, sent) VALUES ('SAMPLE-T-5', 9001, 'SAMPLE-WB-1', 5, 'Some very long random text here', 1790678400000, 'Kencom', NULL, 3, 50.0, 150.0, 'A988', NULL, NULL, 0.0, NULL, 0)")
db.commit()
print('routes:', list(c.execute("SELECT Code, Description FROM routes WHERE Key='LOCAL-ROUTE-1'")))
print('pending:', list(c.execute("SELECT Key, From_Route, sent FROM waybill_trip WHERE sent=0")))
