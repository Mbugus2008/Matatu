import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch.db')
c = db.cursor()
print('TABLES:', [r[0] for r in c.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")])
for t in ('wbill','waybill_trip'):
    try:
        cols = [d[1] for d in c.execute(f'PRAGMA table_info({t})')]
        print(f'\n== {t} cols: {cols}')
        rows = list(c.execute(f'SELECT * FROM {t}'))
        print(f'{t}: {len(rows)} rows')
        for r in rows:
            print(dict(zip(cols, r)))
    except Exception as e:
        print(t, 'ERR', e)
