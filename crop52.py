from PIL import Image
import os
im = Image.open(os.path.join('d:/Projects2/Matatu','emu52.png')).convert('RGB')
crop = im.crop((0, 1650, 1080, 2250))
crop.save(os.path.join('d:/Projects2/Matatu','crop52.png'))
print('saved', crop.size)
