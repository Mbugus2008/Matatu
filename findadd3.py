from PIL import Image
import os
im = Image.open(os.path.join('d:/Projects2/Matatu','emu36.png')).convert('RGB')
px = im.load()
pts = []
for y in range(1150, 1500):
    for x in range(600, 1050):
        r,g,b = px[x,y]
        if b > 110 and b > r + 25 and abs(r-g) < 30 and r < 150:
            pts.append((x,y))
print('count:', len(pts))
if pts:
    xs=[p[0] for p in pts]; ys=[p[1] for p in pts]
    print('bbox x:', min(xs), max(xs), 'y:', min(ys), max(ys))
    print('center:', (min(xs)+max(xs))//2, (min(ys)+max(ys))//2)
