from PIL import Image
im = Image.open(r'd:\Projects2\Matatu\emu92.png').convert('RGB')
px = im.load(); w,h = im.size; print('size', w, h)
best=[]
for y in range(int(h*0.65), h-80):
    for x in range(int(w*0.4), w-20):
        r,g,b = px[x,y]
        if b>230 and r>205 and g>195 and b>g+12 and r>g:
            best.append((x,y))
if best:
    xs=[p[0] for p in best]; ys=[p[1] for p in best]
    print('FAB', (min(xs)+max(xs))//2, (min(ys)+max(ys))//2)
else: print('FAB none')
