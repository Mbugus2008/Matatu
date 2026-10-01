from PIL import Image
import os
im = Image.open(os.path.join('d:/Projects2/Matatu','emu34.png')).convert('RGB')
w,h = im.size
px = im.load()
pts = []
for y in range(1400, 1950):
    for x in range(650, 1080):
        r,g,b = px[x,y]
        if r < 70 and 90 < g < 140 and b < 90:
            pts.append((x,y))
if pts:
    xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
    print('Add Expense bbox x:', min(xs), max(xs), 'y:', min(ys), max(ys), 'count:', len(pts))
    print('center:', (min(xs)+max(xs))//2, (min(ys)+max(ys))//2)
else:
    print('no green text found in region')
