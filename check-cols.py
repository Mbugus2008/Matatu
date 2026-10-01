import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch10.db')
c = db.cursor()
def cols(t):
    return [r[1] for r in c.execute(f"PRAGMA table_info({t})")]
print('wbill cols:', cols('wbill'))
print('waybill_trip cols:', cols('waybill_trip'))
print('Vehicle_Expenses cols:', cols('Vehicle_Expenses'))
print('vehicles cols:', cols('vehicles'))
