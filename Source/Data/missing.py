from tabulate import tabulate  # pip install tabulate

base_bpmf_set = set()
base_char_to_bpmf = {}
phrase_char_to_bpmf = {}
result = []

with open('BPMFBase.txt', 'r', encoding='UTF-8') as f:
    lines = f.readlines()
    for line in lines:
        char, bpmf, _ = line.strip().split(maxsplit=2)
        base_bpmf_set.add(bpmf)
        base_char_to_bpmf.setdefault(char, set()).add(bpmf)

with open('BPMFMappings.txt', 'r', encoding='UTF-8') as f:
    lines = f.readlines()
    for line in lines:
        phrase, bpmfs = line.strip().split(maxsplit=1)
        bpmfs = bpmfs.split()
        for index, char in enumerate(phrase):
            phrase_char_to_bpmf.setdefault(char, set()).add(bpmfs[index])

for char, bpmfs in sorted(phrase_char_to_bpmf.items()):
    if bpmfs.difference(base_bpmf_set):  # exclude 夫, 公, 抓, 意
        continue

    if char not in base_char_to_bpmf:  # ○, 々, 冲, 吡, 嶋, 彝, 条, 渋, 稲, 联, 菓, 装
        result.append([char, '<br>'.join([f'`{bpmf}`' for bpmf in sorted(bpmfs)])])
        continue

    missing = bpmfs.difference(base_char_to_bpmf[char])
    if missing:
        result.append([char, '<br>'.join([f'`{bpmf}`' for bpmf in sorted(missing)])])

with open('missing.md', 'w') as f:
    f.write(tabulate(result, headers=['Character', 'Missing Bopomofo'], tablefmt='github'))
