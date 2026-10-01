import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch9.db')
c = db.cursor()
rows = list(c.execute("SELECT Code FROM routes ORDER BY Code"))
print('routes on device now:', len(rows))
for r in rows: print(' ', r[0])
stale = {'32 - KEN','AMBASSANDER','GPO','KENCOM','TEST-RT'}
present = {r[0] for r in rows}
leftovers = stale & present
print('stale leftovers:', leftovers if leftovers else 'none')
