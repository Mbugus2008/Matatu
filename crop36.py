from PIL import Image
import os
im = Image.open(os.path.join('d:/Projects2/Matatu','emu36.png')).convert('RGB')
crop = im.crop((550, 1100, 1080, 1500))
crop.save(os.path.join('d:/Projects2/Matatu','crop36.png'))
print('saved', crop.size)
