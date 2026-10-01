from PIL import Image
im = Image.open(r'd:\Projects2\Matatu\emu202.png').convert('RGB')
px = im.load(); w,h = im.size
pts=[]
for y in range(200, h-300):
    for x in range(150, w-150):
        r,g,b = px[x,y]
        if r<120 and 120<g<190 and b>220:
            pts.append((x,y))
if pts:
    xs=[p[0] for p in pts]; ys=[p[1] for p in pts]
    print('pill', (min(xs)+max(xs))//2, (min(ys)+max(ys))//2)
else: print('none')
