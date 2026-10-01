from PIL import Image
import os
im = Image.open(os.path.join('d:/Projects2/Matatu','emu35.png')).convert('RGB')
px = im.load()
pts = []
for y in range(900, 1400):
    for x in range(500, 1000):
        r,g,b = px[x,y]
        if b > 100 and b > r + 20 and r > g:
            pts.append((x,y))
if pts:
    xs=[p[0] for p in pts]; ys=[p[1] for p in pts]
    print('purple blob bbox x:', min(xs), max(xs), 'y:', min(ys), max(ys), 'count:', len(pts))
    print('center:', (min(xs)+max(xs))//2, (min(ys)+max(ys))//2)
else:
    print('none')
