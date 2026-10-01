from PIL import Image
im = Image.open(r'd:\Projects2\Matatu\emu87.png').convert('RGB')
px = im.load()
pts = []
for y in range(1850, 2150):
    for x in range(400, 1000):
        r,g,b = px[x,y]
        if abs(r-0)<30 and abs(g-107)<40 and abs(b-63)<40:
            pts.append((x,y))
if pts:
    xs=[p[0] for p in pts]; ys=[p[1] for p in pts]
    print('FAB box:', min(xs), min(ys), max(xs), max(ys), 'center:', (min(xs)+max(xs))//2, (min(ys)+max(ys))//2)
else:
    print('FAB not found')
