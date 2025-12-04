from pathlib import Path
path = Path(r"lib/controllers/vehicles/vehicles.dart")
text = path.read_text()
old = "debugPrint('Error refreshing vehicle list: ' + e.toString());"
new = "debugPrint('Error refreshing vehicle list: {}'.format(e));"
if old in text:
    text = text.replace(old, new)
else:
    text = text.replace("debugPrint('Error refreshing vehicle list: ')", "debugPrint('Error refreshing vehicle list: {}")
path.write_text(text)
