from PIL import Image
import os
for f in ('emu32.png','emu33.png','emu34.png'):
    p = os.path.join('d:/Projects2/Matatu', f)
    im = Image.open(p)
    print(f, im.size)
