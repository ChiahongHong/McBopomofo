from tabulate import tabulate  # pip install tabulate

base_bpmf_set = set()
phrase_bpmf_to_chars = {}
phrase_to_bpmfs = {}
result = []


def find_all(string, target):
    return [i for i, char in enumerate(string) if char == target]


with open('BPMFBase.txt', 'r', encoding='UTF-8') as f:
    for line in f.readlines():
        _, bpmf, _ = line.strip().split(maxsplit=2)
        base_bpmf_set.add(bpmf)

with open('BPMFMappings.txt', 'r', encoding='UTF-8') as f:
    for line in f.readlines():
        phrase, bpmfs = line.strip().split(maxsplit=1)
        phrase_to_bpmfs.setdefault(phrase, []).append(bpmfs)
        bpmfs = bpmfs.split()
        for index, char in enumerate(phrase):
            phrase_bpmf_to_chars.setdefault(bpmfs[index], set()).add(char)

for bpmf, chars in sorted(phrase_bpmf_to_chars.items()):
    if bpmf in base_bpmf_set:
        continue

    for char in chars:
        for phrase, bpmfs in phrase_to_bpmfs.items():
            for index in find_all(phrase, char):
                # we may have multiple same characters, such as 公公 ㄍㄨㄥ ㄍㄨㄥ˙
                temp = [b for b in bpmfs if b.split()[index] == bpmf]
                if len(temp) > 0:
                    result.append([f'{char} `{bpmf}`', '<br>'.join([f'`{t}`' for t in temp]), phrase])
                    break

with open('beep.md', 'w') as f:
    f.write(tabulate(result, headers=['Beep', 'Bopomofo', 'Phrase'], tablefmt='github'))
