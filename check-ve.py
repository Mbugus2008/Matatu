import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch3.db')
c = db.cursor()
tables = [r[0] for r in c.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")]
print('has vehicle_expenses:', 'vehicle_expenses' in tables)
print([t for t in tables if 'ehicle' in t or 'xpense' in t.lower()])
try:
    print('cols:', [d[1] for d in c.execute('PRAGMA table_info(vehicle_expenses)')])
    print('rows:', list(c.execute('SELECT COUNT(*) FROM vehicle_expenses')))
except Exception as e:
    print('vehicle_expenses ERR:', e)
