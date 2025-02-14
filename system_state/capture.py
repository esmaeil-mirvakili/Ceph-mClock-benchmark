import os.path
import threading
import argparse
import subprocess
import re
import time
import json


hdd_disk = ''
ssd_disk = ''

time_pattern = r'^([0-1]?[0-9]|2[0-3]):([0-5]?[0-9]):([0-5]?[0-9])'


def load_disk_path(path):
    global ssd_disk
    global hdd_disk
    with open(path, 'r') as disk_info:
        for line in disk_info.readlines():
            line = line.strip()
            if len(line) > 0:
                parts = line.split(':')
                if parts[0] == 'hdd':
                    hdd_disk = parts[1]
                elif parts[0] == 'ssd':
                    ssd_disk = parts[1]
    print(f'Disks:\n\tHDD: {hdd_disk}\n\tSSD: {ssd_disk}')
    if len(ssd_disk) == 0 or len(hdd_disk) == 0:
        print('Error finding the disks info')
        exit(1)


def run_command(command):
    # Launch the shell command and capture the output
    out = subprocess.run(list(command.split()), stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    stdout_str = out.stdout.strip()
    stderr_str = out.stderr.strip()
    if stderr_str:
        raise Exception(f'Error running command {command}:\n{stderr_str}')
    return stdout_str


def capture_disk(disk_path):
    _, disk_name = os.path.split(disk_path)
    out = run_command(f'iostat -dx {disk_path}')
    headers = []
    data = []
    for line in out.splitlines():
        line = line.strip()
        if line.startswith('Device'):
            headers = line.split()
        if line.startswith(disk_name):
            data = line.split()
    result = {
        f'{disk_name}_type': 'ssd' if disk_path == ssd_disk else 'hdd'
    }
    for name, val in zip(headers, data):
        if name == 'Device':
            continue
        result[f'{disk_name}_{name}'] = float(val)
    return result


def capture_mem():
    out = run_command('free')
    headers = []
    mem = []
    swap = []
    for line in out.splitlines():
        line = line.strip()
        if line.startswith('Mem:'):
            mem = line.split()[1:]
        elif line.startswith('Swap:'):
            swap = line.split()[1:]
        else:
            headers = line.split()
    result = {}
    for name, val in zip(headers, mem):
        result[f'mem_{name}'] = float(val)
    for name, val in zip(headers, swap):
        result[f'swap_{name}'] = float(val)
    return result


def capture_cpu():
    out = run_command('mpstat')
    headers = []
    cpus = {}
    for line in out.splitlines():
        line = line.strip()
        parts = line.split()
        if len(parts) > 0 and re.match(time_pattern, parts[0]):
            if parts[2] == 'CPU':
                headers = parts[3:]
            else:
                cpus[parts[2]] = parts[3:]
    result = {}
    for cpu_name, cpu_data in cpus.items():
        for name, val in zip(headers, cpu_data):
            result[f'cpu_{cpu_name}_{name}'] = float(val)
    return result


def write_to_file(data, path):
    info = f'{time.time_ns()} : {json.dumps(data)}\n'
    with open(path, "a") as file:
        file.write(info)


def capture(out_path):
    io_ssd = capture_disk(ssd_disk)
    io_hdd = capture_disk(hdd_disk)
    mem = capture_mem()
    cpu = capture_cpu()
    merged = {}
    merged.update(io_ssd)
    merged.update(io_hdd)
    merged.update(mem)
    merged.update(cpu)
    write_to_file(merged, out_path)


def run_thread(interval, out_path):
    capture(out_path)
    threading.Timer(interval, run_thread, [interval, out_path]).start()


def parse_args():
    parser = argparse.ArgumentParser('Capture system stats periodically.')
    parser.add_argument('-p', '--path', type=str, default='data/system_stats.txt')
    parser.add_argument('-d', '--disk_info', type=str, default='disks.txt')
    parser.add_argument('-i', '--interval', type=int, default=5)
    return parser.parse_args()


def main(args):
    load_disk_path(args.disk_info)
    run_thread(args.interval, args.path)


if __name__ == '__main__':
    arguments = parse_args()
    main(arguments)
