import argparse
import os
import sys
from generators.rtl.export import export_rtl

import utils.message as message
import generators.preprocess as preprocess
from generators.html.export import export_html
from generators.uvm.export import export_uvm
from parsers.excel.gen_temp import generate_excel
from parsers.parse import parse

__version__ = "0.2.0"

class CommandRunner:
    """
    Provide command-line argument parse and execution functionality

    Subcommands
    ------------
    `excel_template` : generate Excel worksheet templates
    `parse` : parse of register description in Excel (.xlsx) or SystemRDL (.rdl) form, and it supports mixed input
    `generate` : generate RTL modules, documentations, UVM RAL model and C head files
    """
    def build_parser(self):
        """
        Build argument parser
        """
        parser = argparse.ArgumentParser(prog="hrda",
                                         description="Register Design Automation (RDA) Tool")
        parser.add_argument("-v", "--version", action="version", version="%(prog)s {}".format(__version__))
        subparsers = parser.add_subparsers(title="sub-commands",
                                           description="support for generating excel templates, "
                                                       "parsing Excel/SystemRDL specifications, "
                                                       "and generating RTL, UVM RAL, HTML docs "
                                                       "and C header files",
                                           help="see more details in the README and documentaion")

        # Subcommand: excel_template
        parser_excel_template = subparsers.add_parser("excel_template",
                                                      help="generate an Excel template "
                                                           "for register description")
        parser_excel_template.add_argument("-d", "--dir",
                                           default=".",
                                           help="directory for the generated template "
                                                "(default: %(default)s)")
        parser_excel_template.add_argument("-n", "--name",
                                           default="template.xlsx",
                                           help="generated template name "
                                                "(default: %(default)s)")
        parser_excel_template.add_argument("-rnum",
                                           default=1,
                                           type=int,
                                           help="number of registers to be generated "
                                                "in the Excel template (default: %(default)s)")
        parser_excel_template.add_argument("-rname",
                                           default=["TEM1"],
                                           nargs="+",
                                           help="abbreviations of every generated registers "
                                                "in the Excel template. (default: %(default)s)")
        parser_excel_template.add_argument("-l", "--language",
                                           default="cn",
                                           choices=["cn", "en"],
                                           help="language of the generated template "
                                                "(default: %(default)s)")
        parser_excel_template.set_defaults(func=self._generate_excel)

        # Subcommand: parse
        parser_parse = subparsers.add_parser("parse",
                                             help="parse and check register "
                                                  "specifications in Excel/SystemRDL format")
        parser_parse.add_argument("-f", "--file",
                                  nargs="+",
                                  help="Excel/SystemRDL files to parse (must provide the entire path)")
        parser_parse.add_argument("-l", "--list",
                                  help="a list including paths and names of all files "
                                       "(useful for large number of files)")
        parser_parse.add_argument("-grdl", "--gen_rdl",
                                  action="store_true",
                                  help="generate SystemRDL(.rdl) file based on all input Excel(.xlsx) specifications")
        parser_parse.add_argument("-m", "--module",
                                  default="excel_top",
                                  help="used under the situation where all input files are Excel worksheets, "
                                       "which specifies a top addrmap instance name"
                                       "for all input Excel(.xlsx) files (default:%(default)s)")
        parser_parse.add_argument("-gdir", "--gen_dir",
                                  default=".",
                                  help="used under the situation where -grdl/--gen_rdl is set, "
                                       "which specifies the SystemRDL file directory (default:%(default)s)")
        parser_parse.set_defaults(func=self._parse)

        # Subcommand: generate
        parser_generate = subparsers.add_parser("generate",
                                                help="generate RTL, HTML Docs, UVM RAL and C Headers")
        parser_generate.add_argument("-f", "--file",
                                     nargs="+",
                                     help="RDL or Excel (or mixed) files to parse (must provide the entire path)")
        parser_generate.add_argument("-l", "--list",
                                     help="a list including paths and names of all files "
                                          "(useful for large number of files)")
        parser_generate.add_argument("-m", "--module",
                                     default="excel_top",
                                     help="if all input files are Excel worksheets, "
                                          "this option specifies extra top RDL file name "
                                          "for all input Excel(.xlsx) files (default:%(default)s)")
        parser_generate.add_argument("-gdir", "--gen_dir",
                                     default=".",
                                     help="directory to save generated files (default:%(default)s)")
        parser_generate.add_argument("-grtl", "--gen_rtl",
                                     action="store_true",
                                     help="generate synthesiszable SystemVerilog RTL code")
        parser_generate.add_argument("-ghtml", "--gen_html",
                                     action="store_true",
                                     help="generate HTML-format register documentations")
        parser_generate.add_argument("-gral", "--gen_ral",
                                     action="store_true",
                                     help="generate UVM RAL model")
        parser_generate.add_argument("--filter",
                                     nargs="+",
                                     help="filter some instances (support wildcard character)")
        parser_generate.add_argument("-gch", "--gen_cheader",
                                     action="store_true",
                                     help="generate C headers")
        parser_generate.add_argument("-gall", "--gen_all",
                                     action="store_true",
                                     help="generate all")
        parser_generate.set_defaults(func=self._generate)

        return parser

    @staticmethod
    def _generate_excel(args):
        """
        Execution of subcommand `excel_template` as a wrapper.
        This method checks the legality of parameters and pass them down

        Parameter
        ---------
        `args.dir` : 生成寄存器Excel模板的输出目录
        `args.name` : 生成寄存器Excel模板的文件名
        `args.rnum` : 生成Excel模板中寄存器的数量
        `args.rname` : 生成Excel模板中寄存器的名称`list`
        `args.language` : 生成Excel模板的语言, 支持中文/English
        """
        if not os.path.exists(args.dir):
            message.error("directory does not exists!")
            sys.exit(1)
        if not args.name.endswith(".xlsx"):
            args.name += ".xlsx"

        reg_names = args.rname
        if args.rnum > len(reg_names):
            append_name = reg_names[-1]
            for _ in range(len(reg_names), args.rnum):
                reg_names.append(append_name)
        generate_excel(args.dir, args.name, args.rnum, reg_names, args.language)

    @staticmethod
    def _parse(args):
        """
        Execution of subcommand `parse` as a wrapper.
        This method passes `args` parameters down

        Parameter
        ---------
        `args.file` : `list`, all files waiting for parse
        `args.list` : `str`, a file list text file
        `args.gen_rdl` : `bool`, specifies whether to convert Excel worksheets to SystemRDL files
        `args.module` : 输入全部为Excel文件时生成的SystemRDL中顶层addrmap定义名
        `args.gen_dir` : 生成的SystemRDL的目录位置
        """
        parse(args.file,
              args.list,
              args.gen_dir,
              to_generate_rdl=args.gen_rdl,
              excel_top_name=args.module)

    @staticmethod
    def _generate(args):
        """
        子命令`generate`的执行函数, 作为Wrapper向下传递参数

        Parameter
        ---------
        `args.file` : `list`类型, 需要解析所有Excel/SystemRDL文件名
        `args.list` : 存放所有需要解析的Excel文件名的list文本文件名
        `args.module` : 输入全部为Excel文件时生成的reg tree模块名, 也作为生成的SystemRDL中顶层addrmap定义名和根节点regmst名称
        `args.gen_dir` : 生成的SystemRDL的目录位置
        `args.gen_rtl` : `bool`类型, 是否生成RTL Modules
        `args.gen_html` : `bool`类型, 是否生成HTML Docs
        `args.gen_ral` : `bool`类型, 是否生成UVM RAL Model
        `args.gen_cheader` : `bool`类型, 是否生成C Header files
        """
        root = parse(args.file,
                     args.list,
                     args.gen_dir,
                     to_generate_rdl=True,
                     excel_top_name=args.module)

        if not os.path.exists(args.gen_dir):
            message.error("-gdir/--gen_dir option assigns an invalid directory %s" % (args.gen_dir))
            sys.exit(1)

        preprocess.preprocess(root, filter=args.filter)

        if args.gen_all or args.gen_rtl:
            export_rtl(root, args.gen_dir)
        if args.gen_all or args.gen_html:
            export_html(root, args.gen_dir)
        if args.gen_all or args.gen_ral:
            export_uvm(root, args.gen_dir)
        if args.gen_all or args.gen_cheader:
            pass

    def run(self):
        parser = self.build_parser()
        args = parser.parse_args()

        if len(sys.argv) <= 1:
            message.error("no command is specified, use -h/--help option to get instruction")
            sys.exit(1)

        args.func(args)