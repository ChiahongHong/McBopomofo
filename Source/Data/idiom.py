import subprocess

import pandas as pd
from tabulate import tabulate

DEV = True
SORT = True

if DEV:
    subprocess.run(f'git checkout HEAD -- BPMFMappings.txt phrase.occ', shell=True)

df = pd.read_excel('dict_idioms_2020_20250102.xlsx')
idioms = df.set_index('成語').to_dict()['注音']
del idioms['群龍无首']  # since we prefer 群龍無首
del idioms['口蜜劍腹']  # wrong pronunciation ㄇㄧˋ　ㄎㄡˇ　ㄐㄧㄢˋ　ㄈㄨˋ and weird order
idioms['難兄難弟'] = idioms['難兄難弟'].replace('（一）', '').replace('（二）', '（變）')  # format inconsistency
idioms['矯枉過正'] = idioms.pop('矯過正')


def parse(bpmf):
    return {format(s) for s in bpmf.split('（變）')}


def format(bpmf):
    # Tab and space are inconsistent
    bpmf = ' '.join(bpmf.replace('\u3000', ' ').replace('，', ' ').split())
    # Move neutral tone to the end
    if '˙' in bpmf:
        bpmf = ' '.join([f'{s[1:]}˙' if '˙' in s else s for s in bpmf.split()])
    return bpmf


for idiom, bpmf in sorted(idioms.items()):
    idioms[idiom] = parse(bpmf)
    pos = idiom.find('，')
    if pos != -1:
        head, tail = idiom.split('，')
        print(idiom, '-->', head, tail)
        for b in idioms[idiom]:
            idioms.setdefault(head, set()).add(' '.join(b.split()[:pos]))  # pos - 1 + 1
            idioms.setdefault(tail, set()).add(' '.join(b.split()[pos:]))
        del idioms[idiom]
    elif len(idiom) > 6:
        print(idiom, '--> Skip')
        del idioms[idiom]

data = {}
result = []
added = dict()
with open('BPMFMappings.txt', 'r+', encoding='UTF-8') as f:
    for line in f.readlines():
        phrase, bpmf = line.strip().split(maxsplit=1)
        data.setdefault(phrase, set()).add(bpmf)

    for idiom, bpmf in sorted(idioms.items()):
        if idiom in data:
            diff = bpmf.difference(data[idiom])
            if not diff:
                continue

            for d in diff:
                assert len(idiom) == len(d.split()), f'{idiom} {d}'
                for index, char in enumerate(idiom):
                    added.setdefault(char, set()).add(d.split()[index])
                f.write(f'{idiom} {d}\n')
            result.append([idiom, '<br>'.join([f'`{d}`' for d in diff]), 'Patch'])
        else:
            for b in bpmf:
                assert len(idiom) == len(b.split()), f'{idiom} {b}'
                for index, char in enumerate(idiom):
                    added.setdefault(char, set()).add(b.split()[index])
                f.write(f'{idiom} {b}\n')
            result.append([idiom, '<br>'.join([f'`{b}`' for b in bpmf]), 'New'])

        # added = added.union({char for char in idiom})

base = {}
with open('BPMFBase.txt', 'r+', encoding='UTF-8') as f:
    for line in f.readlines():
        char, bpmf, _ = line.strip().split(maxsplit=2)
        base.setdefault(char, set()).add(bpmf)
    print('\nWe have to add following characters into BPMFBase.txt:')
    for char, bpmf in sorted(added.items()):
        if char in base:
            diff = bpmf.difference(base[char])
            if not diff:
                continue
            print(f'{char} {', '.join([d for d in diff])}')
        else:
            print(f'{char} {', '.join([b for b in bpmf])}')
    # print('、'.join([f'{char} {added[char]}' for char in sorted(set(added).difference(set(base)))]))

with open('phrase.occ', 'a', encoding='UTF-8') as f:
    for idiom in sorted(set(idioms).difference(data)):
        f.write(f'{idiom} 0\n')

with open('idiom.md', 'w') as f:
    f.write(tabulate(result, headers=['Idiom', 'Bopomofo', 'Type'], tablefmt='github'))

if SORT:
    subprocess.run(f'LC_ALL=c sort -o BPMFMappings.txt BPMFMappings.txt', shell=True)
    subprocess.run(f'LC_ALL=c sort -o phrase.occ phrase.occ', shell=True)
