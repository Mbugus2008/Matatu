import sqlite3
db = sqlite3.connect(r'd:\Projects2\Matatu\emu-mbranch.db')
c = db.cursor()
cols = [d[1] for d in c.execute('PRAGMA table_info(agents)')]
print('agents cols:', cols)
for r in c.execute('SELECT Agent_Code, Name, Status, Account_type FROM agents'):
    print(r)
