import sys


def normalize_mapping(mapping):
    """Keep GameMaker's A/B positions when PortMaster labels them for Nintendo."""
    if '# nintendo layout' not in mapping.lower():
        return mapping
    lines = []
    for line in mapping.splitlines(keepends=True):
        fields = line.split(',')
        for index in range(2, len(fields)):
            if fields[index].startswith('a:'):
                fields[index] = 'b:' + fields[index][2:]
            elif fields[index].startswith('b:'):
                fields[index] = 'a:' + fields[index][2:]
        lines.append(','.join(fields))
    return ''.join(lines)


if __name__ == '__main__':
    sys.stdout.write(normalize_mapping(sys.stdin.read()))
