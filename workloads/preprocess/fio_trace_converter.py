import argparse
import os.path
from pathlib import Path
import yaml


def spc_parse(line, block_size=512):
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
    res['time_offset'] = int(float(parts[4]) * 1000_000)  # Timestamp
    res['lba'] = int(parts[1]) * block_size  # Logical Block Address (Offset)
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
    res['time_offset'] = int(float(parts[3]) * 1000)  # Timestamp
    res['lba'] = parts[1]  # Logical Block Address (Offset)
    res['size'] = parts[2]  # Size in bytes
    return res


def store(entries, output_path, rbd_image):
    with open(output_path, "w") as out_file:
        out_file.write("fio version 3 iolog\n")
        out_file.write(f"0 {rbd_image} add\n")
        out_file.write(f"0 {rbd_image} open\n")
        for entry in entries:
            out_file.write(f"{entry['time_offset']} {rbd_image} {entry['operation']} {entry['lba']} {entry['size']}\n")


def store_configs(output_path, cbt_cnf_path, trace_paths, duration):
    cbt_conf = {}
    with open(cbt_cnf_path, "r") as stream:
        try:
            cbt_conf = yaml.safe_load(stream)
        except yaml.YAMLError as e:
            raise e
    bench_config = cbt_conf['benchmarks']['fio']
    benchmarks = {}
    for i, trace_path in enumerate(trace_paths):
        conf = {}
        conf.update(bench_config)
        if 'extra_config' not in conf:
            conf['extra_config'] = {}
        conf['extra_config']['read_iolog'] = trace_path
        conf['order'] = i
        benchmarks[f'fio_{i}'] = conf
    cbt_conf['benchmarks'] = benchmarks
    cbt_conf['cluster']['pool_profiles']['rbdrecov']['prefill_recov_time'] = duration
    cnf_out_path = os.path.join(output_path, 'cbt.yaml')
    with open(cnf_out_path, 'w') as fp:
        yaml.dump(cbt_conf, fp)


def get_rbd_image(cbt_cnf_path):
    return '/dev/rbd0'


def main(args):
    input_filename = Path(args.input).stem
    rbd_image = get_rbd_image(args.yaml_cbt)
    if not os.path.exists(args.output):
        os.makedirs(args.output)
    index = 0
    first_timestamp = None
    entries = []
    trace_paths = []
    with open(args.input, "r") as in_file:
        for line in in_file:
            parsed = None
            if args.type == 'spc':
                parsed = spc_parse(line)
            elif args.type == 'meta':
                parsed = meta_parse(line)
            if parsed is None:
                continue
            if first_timestamp is None:
                first_timestamp = parsed['time_offset']
            if args.chunked and parsed['time_offset'] - first_timestamp > args.duration * 1_000_000:
                trace_output = os.path.join(args.output, f'{input_filename}_{index}.txt')
                store(entries, trace_output, rbd_image)
                entries = []
                trace_paths.append(trace_output)
                first_timestamp = parsed['time_offset']
                index += 1
                if index >= args.limit - 1:
                    break
            parsed['time_offset'] = parsed['time_offset'] - first_timestamp
            entries.append(parsed)
    if len(entries) > 0:
        trace_output = os.path.join(args.output, f'{input_filename}_{index}.txt')
        store(entries, trace_output, rbd_image)
        trace_paths.append(trace_output)
    store_configs(args.output, args.yaml_cbt, trace_paths, args.duration)


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
    parser.add_argument('-c', '--chunked', action="store_true", dest='chunked',
                        help='If enabled, it break the workload to chunks with size of `duration`.')
    parser.add_argument('-d', '--duration', metavar='duration', type=int,
                        required=False, default=600, dest='duration',
                        help='Chunk duration.')
    parser.add_argument('-l', '--limit', metavar='limit', type=int,
                        required=False, default=30, dest='limit',
                        help='Chunk number limit.')
    parser.add_argument('-y', '--yam_cbt', metavar='yaml_cbt',
                        required=False, default='cbt_template.yaml', dest='yaml_cbt',
                        help='CBT config path.')
    main(parser.parse_args())
