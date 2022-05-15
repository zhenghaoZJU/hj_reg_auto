import os

import utils.message as message
from peakrdl.uvm import UVMExporter
from systemrdl.node import RootNode

def export_uvm(root:RootNode, out_dir:str):
    """
    Export UVM RAL model package

    Parameter
    ---------
    `root` : `systemrdl.node.RootNode` systemrdl-compiler解析完以后的寄存器模型根节点
    `out_dir` : 输出UVM RAL模型的目录, 会在该目录下创建一个`uvm_ral`子目录, 存放输出的模型
    """
    exporter = UVMExporter()
    export_file = os.path.join(out_dir, "uvm_test.sv")

    try:
        exporter.export(root, export_file, reuse_class_definitions=False)
    except:
        message.error("UVM RAL exporter aborted due to previous errors")
    else:
        message.info("save UVM RAL model in: %s" % (export_file))