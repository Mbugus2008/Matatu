from PIL import Image
import os
im = Image.open(os.path.join('d:/Projects2/Matatu','emu41.png')).convert('RGB')
px = im.load()
pts = []
for y in range(300, 2400):
    for x in range(300, 1080):
        r,g,b = px[x,y]
        if b > 120 and b > r + 30 and abs(r-g) < 30 and r < 160 and g < 140:
            pts.append((x,y))
print('purple pixels:', len(pts))
if pts:
    xs=[p[0] for p in pts]; ys=[p[1] for p in pts]
    print('bbox x:', min(xs), max(xs), 'y:', min(ys), max(ys))
