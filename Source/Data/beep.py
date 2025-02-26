class Mapping:
    keymaps = "1qaz2wsxedcrfv5tgbyhnujm8ik,9ol.0p;/-3467"
    letters = "ㄅㄆㄇㄈㄉㄊㄋㄌㄍㄎㄏㄐㄑㄒㄓㄔㄕㄖㄗㄘㄙㄧㄨㄩㄚㄛㄜㄝㄞㄟㄠㄡㄢㄣㄤㄥㄦˇˋˊ˙"
    mapping = dict(zip([*letters], [*keymaps]))

    @staticmethod
    def letterToKey(letter):
        return Mapping.mapping[letter]


class Char:
    def __init__(self, char, bpmf, pinyin, mapping, encoding):
        self.char = char
        self.bpmf = bpmf
        self.pinyin = pinyin
        self.mapping = mapping
        self.encoding = encoding

    def __str__(self):
        return f'{self.char} {self.bpmf} {self.pinyin} {self.mapping} {self.encoding}'


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
    # just sort by mapping key, our characters order will be preserved
    data.sort(key=lambda x: x.mapping)
    with open('BPMFBase2.txt', 'w', encoding='UTF-8') as f:
        for row in data:
            f.write(f'{row}\n')


# def read_bpmf_phrase():
#     with open('BPMFMappings.txt', 'r', encoding='UTF-8') as f:
#         lines = f.readlines()
#         for line in lines:
#             phrase, bpmf = line.split(maxsplit=1)
#             bpmf = bpmf.split()
#             for index, char in enumerate(phrase):
#                 phrase_char_to_bpmf.setdefault(char, set()).add(bpmf[index])


if __name__ == '__main__':
    data = read_bpmf_base()
    write_bpmf_base(data)
