import configparser
import argparse
import yaml
from pathlib import Path


def read_yaml(file):
    with open(file, "r") as stream:
        try:
            return yaml.safe_load(stream)
        except yaml.YAMLError:
            return {}


class ConfigContent:
    def __init__(self, path):
        self.path = path
        self.config = None

    def open(self):
        pass

    def convert(self, value, params):
        if isinstance(value, dict):
            value = params[int(list(value.keys())[0])]
        return value

    def update(self, key, value, params, sections=None):
        if sections is None:
            sections = []
        conf = self.config
        for section in sections:
            conf = conf[section]
        conf[key] = self.convert(value, params)

    def get(self, key, sections=None):
        if sections is None:
            sections = []
        conf = self.config
        for section in sections:
            conf = conf[section]
        return conf[key]

    def write(self, file):
        pass


class YamlConfigContent(ConfigContent):
    def open(self):
        self.config = read_yaml(self.path)

    def write(self, file):
        with open(file, 'w') as fp:
            yaml.dump(self.config, fp)


class ConfConfigContent(ConfigContent):
    def open(self):
        self.config = configparser.ConfigParser()
        self.config.read(self.path)

    def convert(self, value, params):
        if isinstance(value, dict):
            value = params[int(list(value.keys())[0])]
        return str(value)

    def write(self, file):
        with open(file, 'w') as fp:
            self.config.write(fp)


def read_benchmarks(config_path):
    benchmarks_conf = read_yaml(config_path)
    configs = benchmarks_conf['configs']
    benchmark_list = benchmarks_conf['benchmarks']
    benchmarks = {}
    for benchmark in benchmark_list:
        bench_configs = benchmark['configs']
        bench_name = benchmark['name']
        config_files = {}
        for bench_conf in bench_configs:
            conf_name = bench_conf['name']
            conf_params = bench_conf['params']
            if conf_name in configs:
                conf_ref = configs[conf_name]
                if conf_ref['file'] not in config_files:
                    if conf_ref['file'].endswith('.conf'):
                        config_files[conf_ref['file']] = ConfConfigContent(conf_ref['file'])
                    elif conf_ref['file'].endswith('.yaml'):
                        config_files[conf_ref['file']] = YamlConfigContent(conf_ref['file'])
                    else:
                        print('Error: config file %s not supported' % conf_ref['file'])
                        exit(1)
                    config_files[conf_ref['file']].open()
                reference = config_files[conf_ref['file']]
                sections = []
                if 'section' in conf_ref:
                    sections.append(conf_ref['section'])
                if 'sub_section' in conf_ref:
                    sections.append(conf_ref['sub_section'])
                for key, value in conf_ref['values'].items():
                    reference.update(key, value, conf_params, sections=sections)
        benchmarks[bench_name] = config_files
    return benchmarks


def main(args):
    benchmarks = read_benchmarks(args.config)
    benchmarks_folder = Path.home().joinpath('benchmarks')
    Path.mkdir(benchmarks_folder)
    for bench_name, bench_configs in benchmarks.items():
        bench_folder = benchmarks_folder.joinpath(bench_name)
        Path.mkdir(bench_folder)
        for conf_file, config in bench_configs.items():
            file = bench_folder.joinpath(conf_file)
            config.write(file)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Run experiments.')
    parser.add_argument('-c', '--conf', metavar='config',
                        required=True, dest='config',
                        help='Experiments\' config file')
    main(parser.parse_args())

# config = configparser.ConfigParser()
# config.read('ceph.conf')
# print(config['global'].get('test'))