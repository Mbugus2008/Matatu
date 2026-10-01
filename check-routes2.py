import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch8.db')
c = db.cursor()
print('routes on device:', c.execute("SELECT COUNT(*) FROM routes").fetchone()[0])
for r in c.execute("SELECT Code FROM routes ORDER BY Code"):
    print(' ', r[0])
