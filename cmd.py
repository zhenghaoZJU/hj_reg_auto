import argparse
import os
import sys

import utils.message as message
from excel.check import parse_excel, parse_rdl, show_rules
from excel.gen_temp import generate_excel


__version__ = "0.1.0"

class CommandRunner:
    """
    提供命令行解析和执行功能

    子命令
    -----
    `excel_template` : 生成寄存器Excel模板
    `rdl_template` : 生成寄存器SystemRDL模板
    `parse_excel` : 对Excel形式的寄存器说明进行规则检查
    `parse_rdl` : 对SystemRDL形式的寄存器说明进行规则检查
    """
    def build_parser(self):
        """
        构建命令行解析器
        """
        parser = argparse.ArgumentParser(prog="regslv",
                                         description="register slave (regslv) RTL automation tool.")
        parser.add_argument('--version', action='version', version='%(prog)s {}'.format(__version__))
        subparsers = parser.add_subparsers(title="sub-commands",
                                           description="now support for generating excel templates, " 
                                                       "parsing Excel/SystemRDL specifications, "
                                                       "and generating RTL, RAL, documentation files and C header files",
                                           help="see more details in the documentaion")
        # 子命令：生成寄存器Excel模板
        parser_excel_template = subparsers.add_parser("excel_template",
                                                      help="generate an Excel template for register description")
        parser_excel_template.add_argument("-p", "--path",
                                           default=".",
                                           help="path for the generated template (Default: %(default)s)")
        parser_excel_template.add_argument("-n", "--name",
                                           default="template.xlsx",
                                           help="generated template name (Default: %(default)s)")
        parser_excel_template.add_argument("--rnum",
                                           default=1,
                                           type=int,
                                           help="number of registers to be generated in the Excel template (Default: %(default)s)")
        parser_excel_template.add_argument("--rname",
                                           default=["TEM1"],
                                           nargs="+",
                                           help="abbreviations of every generated registers "
                                                "in the Excel template. (Default: %(default)s)")
        parser_excel_template.add_argument("-l", "--language",
                                           default="cn",
                                           choices=["cn", "en"],
                                           help="language of the generated template. (Default: %(default)s)")
        parser_excel_template.set_defaults(func=self._generate_excel)

        # 子命令：生成寄存器SystemRDL模板
        
        # 子命令：解析Excel形式的寄存器描述
        parser_parse_excel = subparsers.add_parser("parse_excel",
                                                help="parse and check register specifications in Excel files")
        parser_parse_excel.add_argument("-f", "--file",
                                        nargs="+",
                                        help="Excel files to parse. (must provide the entire file path)")
        parser_parse_excel.add_argument("-l", "--list",
                                        help="a list file including paths and names of all Excel files (useful for large number of files)")
        parser_parse_excel.add_argument("-s", "--show",
                                        action="store_true",
                                        help="show parsing rules")
        parser_parse_excel.set_defaults(func=self._parse_excel)

        # 子命令：解析SystemRDL形式的寄存器描述
        parser_parse_rdl = subparsers.add_parser("parse_rdl",
                                                 help="parse and check register specifications in SystemRDL files")
        parser_parse_rdl.add_argument("-f", "--file",
                                      help="SystemRDL files to parse (must provide the entire file path)")
        parser_parse_rdl.add_argument("-l", "--list",
                                      help="a list including paths and names of all SystemRDL files (useful for large number of files)")                      
        parser_parse_rdl.set_defaults(func=self._parse_rdl)

        return parser

    # 子命令执行函数
    # Wrapper
    @staticmethod
    def _generate_excel(args):
        """
        子命令`excel_template`的执行函数, 作为Wrapper检查参数合法性并向下传递
        """
        if not os.path.exists(args.path):
            message.error("path does not exists!")
            sys.exit(1)
        if not ".xlsx" in args.name:
            args.name += ".xlsx" 

        reg_names = args.rname
        if args.rnum > len(reg_names):
            append_name = reg_names[-1]
            for _ in range(len(reg_names), args.rnum):
                reg_names.append(append_name)
        generate_excel(args.path, args.name, args.rnum, reg_names, args.language)

    @staticmethod
    def _parse_excel(args):
        if args.show:
            show_rules()
        # 单个或多个Excel文件作为输入
        if args.file is not None:
            if args.list is not None:
                message.warning("cannot use -f/--file and -l/--list options at the same time,"
                                "-l/--list option will be ignored")
            for file in args.file:
                if not os.path.exists(file):
                    message.error("input file:%s does not exists!" %(file))
                    sys.exit(1)
                if not os.path.splitext(file)[-1] == ".xlsx":
                    message.error("wrong file format! (should be .xlsx)")
                    sys.exit(1)

            # 以list形式把一个或多个Excel文件名传进去
            parse_excel(args.file)

        # 多个Excel文件作为输入,文件路径放在一个list文本文件中
        elif args.list is not None:
            if not os.path.exists(args.list):
                message.error("list file does not exists!")
                sys.exit(1)
            else:
                with open(args.list, "r") as f:
                    flist = []
                    lines = f.readlines()
                    for cnt, line in enumerate(lines):
                        if not os.path.exists(line):
                            message.error("list file:%s line:%d input file:%s does not exists!" %(args.list, cnt, line))
                            sys.exit(1)
                        if not os.path.splitext(line)[-1] == ".xlsx":
                            message.error("wrong file format! (should be .xlsx)")
                            sys.exit(1)
                        flist.append(line)

            # 以list形式把一个或多个Excel文件名传进去
            parse_excel(flist)
        elif not args.show:
            message.error("one of the -f/--file and -l/--list options must be provided!")
            sys.exit(1)

    @staticmethod
    def _parse_rdl(args):
        # 单个或多个RDL文件作为输入
        if args.file is not None:
            if args.list is not None:
                message.warning("cannot use -f/--file and -l/--list options at the same time,"
                                "-l/--list option will be ignored")
            for file in args.file:
                if not os.path.exists(file):
                    message.error("input file:%s does not exists!" %(file))
                    sys.exit(1)
                if not os.path.splitext(file)[-1] == ".rdl":
                    message.error("wrong file format! (should be .rdl)")
                    sys.exit(1)

            # 以list形式把一个或多个RDL文件名传进去
            parse_rdl(args.file)

        # 多个RDL文件作为输入,文件路径放在一个list文本文件中
        elif args.list is not None:
            if not os.path.exists(args.list):
                message.error("list file does not exists!")
                sys.exit(1)
            else:
                with open(args.list, "r") as f:
                    flist = []
                    lines = f.readlines()
                    for cnt, line in enumerate(lines):
                        if not os.path.exists(line):
                            message.error("list file:%s line:%d input file:%s does not exists!" %(args.list, cnt, line))
                            sys.exit(1)
                        if not os.path.splitext(line)[-1] == ".rdl":
                            message.error("wrong file format! (should be .rdl)")
                            sys.exit(1)
                        flist.append(line)

            # 以list形式把一个或多个Excel文件名传进去
            parse_rdl(flist)
        else:
            message.error("one of the -f/--file and -l/--list options must be provided!")
            sys.exit(1)

    def run(self):
        parser = self.build_parser()
        args = parser.parse_args()
        args.func(args)

if __name__ == "__main__":
    runner =  CommandRunner()
    runner.run()
