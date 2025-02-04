import argparse


def spc_parse(line):
    parts = line.strip().split(",")
    if len(parts) < 5:
        return None
    res = {}
    op_type = parts[3].lower()
    if op_type == "r":
        res['operation'] = "read"
    elif op_type == "w":
        res['operation'] = "write"
    else:
        return None
    res['time_offset'] = float(parts[4])  # Timestamp
    res['lba'] = parts[1]  # Logical Block Address (Offset)
    res['size'] = parts[2]  # Size in bytes
    return res


def meta_parse(line):
    parts = line.strip().split(" ")
    if len(parts) < 5 or parts[0] == '#':
        return None
    res = {}
    op_type = int(parts[4])
    if op_type in [1, 2, 5]:
        res['operation'] = "read"
    elif op_type in [3, 4, 6]:
        res['operation'] = "write"
    else:
        return None
    res['time_offset'] = float(parts[3])/1000  # Timestamp
    res['lba'] = parts[1]  # Logical Block Address (Offset)
    res['size'] = parts[2]  # Size in bytes
    return res


def main(args):
    first_timestamp = None
    with open(args.input, "r") as f, open(args.output, "w") as fout:
        for line in f:
            parsed = None
            if args.type == 'spc':
                parsed = spc_parse(line)
            elif args.type == 'meta':
                parsed = meta_parse(line)
            if parsed is None:
                continue
            if args.type == 'meta':
                if first_timestamp is None:
                    first_timestamp = parsed['time_offset']
                parsed['time_offset'] = parsed['time_offset'] - first_timestamp
            # Write in FIO format
            fout.write(f"{parsed['time_offset']} {parsed['operation']} {parsed['lba']} {parsed['size']}\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='spc to fio workload converter.')
    parser.add_argument('-i', '--input', metavar='input',
                        required=True, dest='input',
                        help='SPC input file')
    parser.add_argument('-t', '--type', metavar='type',
                        required=False, dest='type',
                        default='spc', choices=['spc', 'meta'],
                        help='Input type')
    parser.add_argument('-o', '--output', metavar='output',
                        required=True, dest='output',
                        help='FIO trace output file')
    main(parser.parse_args())
