class Char:
    def __init__(self, char, bpmf, pinyin, keymap, encoding):
        self.char = char
        self.bpmf = bpmf
        self.pinyin = pinyin
        self.keymap = keymap
        self.encoding = encoding

    def __str__(self):
        return f'{self.char} {self.bpmf} {self.pinyin} {self.keymap} {self.encoding}'


class Phrase:
    def __init__(self, phrase, bpmf):
        self.phrase = phrase
        self.bpmf = bpmf

    def __str__(self):
        return f'{self.phrase} {self.bpmf}'


def read_bpmf_base():
    with open('BPMFBase.txt', 'r', encoding='UTF-8') as f:
        return [Char(*row.split()) for row in f.readlines()]


def write_bpmf_base(data: list[Char]):
    # sort is quaranteed to be stable in Python
    # just sort by keymap, our characters order will be preserved
    data.sort(key=lambda x: x.keymap)
    with open('BPMFBase2.txt', 'w', encoding='UTF-8') as f:
        for row in data:
            f.write(f'{row}\n')


# def read_bpmf_mappings():
#     with open('BPMFMappings.txt', 'r', encoding='UTF-8') as f:
#         return [Phrase(*row.split(maxsplit=1)) for row in f.readlines()]


if __name__ == '__main__':
    data = read_bpmf_base()
    write_bpmf_base(data)
