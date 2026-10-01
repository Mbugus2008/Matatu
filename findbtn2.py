from PIL import Image
import os
im = Image.open(os.path.join('d:/Projects2/Matatu','emu52.png')).convert('RGB')
px = im.load()
pts = []
for y in range(1400, 1900):
    for x in range(650, 1080):
        r,g,b = px[x,y]
        if r < 70 and 90 < g < 140 and b < 90:
            pts.append((x,y))
if pts:
    xs=[p[0] for p in pts]; ys=[p[1] for p in pts]
    print('Add Expense bbox x:', min(xs), max(xs), 'y:', min(ys), max(ys), 'count:', len(pts))
    print('center:', (min(xs)+max(xs))//2, (min(ys)+max(ys))//2)
else:
    print('not found in y1400-1900; scanning 1200-2400')
    for y in range(1200, 2400):
        for x in range(500, 1080):
            r,g,b = px[x,y]
            if r < 70 and 90 < g < 140 and b < 90:
                pts.append((x,y))
    xs=[p[0] for p in pts]; ys=[p[1] for p in pts]
    print('bbox x:', min(xs), max(xs), 'y:', min(ys), max(ys), 'count:', len(pts))
    print('center:', (min(xs)+max(xs))//2, (min(ys)+max(ys))//2)
