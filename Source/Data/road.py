import csv

from tabulate import tabulate  # pip install tabulate

data = set()
roads = {}

with open('BPMFMappings.txt', 'r', encoding='UTF-8') as f:
    for line in f.readlines():
        phrase, _ = line.strip().split(maxsplit=1)
        data.add(phrase)

with open('opendata113road.csv', 'r', encoding='utf-8-sig', newline='') as f:
    for line in csv.DictReader(f):
        road = line['road'].strip()
        if not road or road in data:  # skip empty or existing road
            continue
        roads[road] = roads.get(road, 0) + 1

roads = [[road, count] for road, count in sorted(
    roads.items(), key=lambda item: item[1], reverse=True
)]

print(f'Count: {len(roads)}')

with open('road.md', 'w') as f:
    f.write('\n'.join([r for r, _ in roads]))
    # f.write(tabulate(roads, headers=['Road', 'Count'], tablefmt='github'))
