import json
from pathlib import Path
ROOT=Path(r'E:\old_flutter\Quran-App-master')
targets={
 13:[28],65:[2],3:[139,134],94:[6],57:[4],50:[16],2:[216],1:[6],10:[62],9:[40],42:[37],14:[7],16:[18],39:[53],12:[87]
}
for surah,ayahs in targets.items():
    data=json.loads((ROOT/'assets'/'quran'/'uthmani'/f'{surah}.json').read_text(encoding='utf-8'))
    for a in ayahs:
        print(f'--- {surah}:{a} ---')
        print(data.get(str(a),'<MISSING>'))
