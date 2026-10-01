import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch10.db')
c = db.cursor()
print([r[0] for r in c.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")])
