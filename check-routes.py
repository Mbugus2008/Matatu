import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch7.db')
c = db.cursor()
print('device routes:')
for r in c.execute("SELECT Code, Description, sent FROM routes ORDER BY Code"):
    print(r)
