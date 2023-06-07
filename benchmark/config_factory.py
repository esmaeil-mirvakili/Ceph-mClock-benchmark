import configparser
import argparse
import os.path
import re
import shutil
import yaml
from pathlib import Path


def read_yaml(file):
    with open(file, "r") as stream:
        try:
            return yaml.safe_load(stream)
        except yaml.YAMLError as e:
            raise e


class ConfigContent:
    def __init__(self, path):
        self.path = path
        self.config = None

    def open(self):
        pass

    def new_conf(self):
        pass

    def format(self, value, params):
        if isinstance(value, dict):
            value = params[int(list(value.keys())[0])]
        return value

    def convert(self, value):
        return value

    def update(self, key, value, params, sections=None):
        if sections is None:
            sections = []
        conf = self.config
        for section in sections:
            if section not in conf:
                conf[section] = self.new_conf()
            conf = conf[section]
        conf[key] = self.format(self.convert(value), params)

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

    def new_conf(self):
        return {}

    def write(self, file):
        with open(file, 'w') as fp:
            yaml.dump(self.config, fp)


class ConfConfigContent(ConfigContent):
    def open(self):
        self.config = configparser.ConfigParser()
        self.config.read(self.path)

    def new_conf(self):
        return configparser.ConfigParser()

    def convert(self, value):
        if isinstance(value, bool):
            return 1 if value else 0
        return value

    def format(self, value, params):
        if isinstance(value, dict):
            value = params[int(list(value.keys())[0])]
        return str(value)

    def write(self, file):
        with open(file, 'w') as fp:
            self.config.write(fp)


def evaluate_vars_str(param: str, variables):
    if not variables:
        return param
    if param.startswith("$"):
        if param[1:] in variables:
            return variables[param[1:]]
        else:
            raise Exception(f'Variable "{param[1:]}" not defined.')
    result = re.findall(r"\$\{\w[\w\d_]*\}", param)
    for r in result:
        var_name = r[2:-1]
        if var_name not in variables:
            raise Exception(f'Variable "{var_name}" not defined.')
        param = param.replace(r, str(variables[var_name]))
    return param


def evaluate_vars(param_list: list, variables):
    if not variables:
        return param_list
    for i in range(len(param_list)):
        if isinstance(param_list[i], str):
            param_list[i] = evaluate_vars_str(param_list[i], variables)
        elif isinstance(param_list[i], list):
            param_list[i] = evaluate_vars(param_list[i], variables)
    return param_list


def read_benchmarks(config_path, configs=None, variables=None):
    if variables is None:
        variables = {}
    if configs is None:
        configs = {}
    benchmarks_conf = read_yaml(config_path)
    if 'configs' in benchmarks_conf:
        configs.update(benchmarks_conf['configs'])
    benchmark_list = benchmarks_conf['benchmarks']
    if 'variables' in benchmarks_conf:
        variables.update(benchmarks_conf['variables'])
    benchmarks = {}
    dependencies = {}
    for benchmark in benchmark_list:
        bench_configs = benchmark['configs']
        bench_name = benchmark['name']
        dependencies[bench_name] = []
        config_files = {}
        for bench_conf in bench_configs:
            conf_name = bench_conf['name']
            conf_params = evaluate_vars(bench_conf['params'], variables)
            if conf_name in configs:
                conf_ref = configs[conf_name]
                if 'dependencies' in conf_ref:
                    if isinstance(conf_ref['dependencies'], list):
                        dependencies[bench_name] += conf_ref['dependencies']
                    elif isinstance(conf_ref['dependencies'], str):
                        dependencies[bench_name].append(conf_ref['dependencies'])
                out = conf_ref['out'] if 'out' in conf_ref else conf_ref['file']
                if out not in config_files:
                    if conf_ref['file'].endswith('.conf'):
                        config_files[out] = ConfConfigContent(conf_ref['file'])
                    elif conf_ref['file'].endswith('.yaml'):
                        config_files[out] = YamlConfigContent(conf_ref['file'])
                    else:
                        print('Error: config file %s not supported' % conf_ref['file'])
                        exit(1)
                    config_files[out].open()
                reference = config_files[out]
                sections = conf_ref['section']
                for key, value in conf_ref['values'].items():
                    reference.update(key, value, conf_params, sections=sections)
        bench_name = evaluate_vars_str(bench_name, variables)
        benchmarks[bench_name] = config_files
    return benchmarks, dependencies


def extract(path):
    configs = None
    variables = None
    benchmarks_conf = read_yaml(path)
    if 'configs' in benchmarks_conf:
        configs = benchmarks_conf['configs']
    if 'variables' in benchmarks_conf:
        variables = benchmarks_conf['variables']
    return configs, variables


def main(args):
    repeat = args.repeat
    configs, variables = extract(args.global_config)
    benchmarks, dependencies = read_benchmarks(args.config, configs=configs, variables=variables)
    benchmarks_folder = Path.home().joinpath('benchmarks')
    if not os.path.exists(benchmarks_folder):
        Path.mkdir(benchmarks_folder)
    for rep in range(repeat):
        for bench_name, bench_configs in benchmarks.items():
            bench_post = f'_{rep}' if repeat > 1 else ''
            bench_folder = benchmarks_folder.joinpath(bench_name+bench_post)
            if os.path.exists(bench_folder):
                os.removedirs(bench_folder)
            Path.mkdir(bench_folder)
            for conf_file, config in bench_configs.items():
                file = bench_folder.joinpath(conf_file)
                config.write(file)
            for dependency in dependencies[bench_name]:
                if os.path.exists(dependency):
                    dst = bench_folder.joinpath(dependency)
                    shutil.copyfile(dependency, dst)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Run experiments.')
    parser.add_argument('-c', '--conf', metavar='config',
                        required=True, dest='config',
                        help='Experiments\' config file')
    parser.add_argument('-g', '--glob', metavar='global_config',
                        required=False, dest='global_config',
                        default='global_configs.yaml',
                        help='Experiments\' global config file')
    parser.add_argument('-r', '--reps', metavar='repeat',
                        required=False, dest='repeat',
                        default=1,
                        help='Experiments\' repeat')
    main(parser.parse_args())

# config = configparser.ConfigParser()
# config.read('ceph.conf')
# print(config['global'].get('test'))
