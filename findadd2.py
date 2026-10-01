from PIL import Image
import os
im = Image.open(os.path.join('d:/Projects2/Matatu','emu35.png')).convert('RGB')
px = im.load()
pts = []
for y in range(1020, 1200):
    for x in range(640, 900):
        r,g,b = px[x,y]
        if b > 110 and b > r + 25 and abs(r-g) < 25 and r < 140:
            pts.append((x,y))
print('count:', len(pts))
if pts:
    xs=[p[0] for p in pts]; ys=[p[1] for p in pts]
    print('bbox x:', min(xs), max(xs), 'y:', min(ys), max(ys))
    print('center:', (min(xs)+max(xs))//2, (min(ys)+max(ys))//2)
