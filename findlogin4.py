from PIL import Image
import os
im = Image.open(os.path.join('d:/Projects2/Matatu','emu73.png')).convert('RGB')
px = im.load()
pts = []
for y in range(300, 2100):
    for x in range(200, 900):
        r,g,b = px[x,y]
        if b > 180 and g > 120 and r < 120 and b > r + 80:
            pts.append((x,y))
if pts:
    xs=[p[0] for p in pts]; ys=[p[1] for p in pts]
    print('pill center:', (min(xs)+max(xs))//2, (min(ys)+max(ys))//2)
else:
    print('no pill')
