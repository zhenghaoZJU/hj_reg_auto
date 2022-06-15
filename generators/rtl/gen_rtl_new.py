import os
import sys
from math import log, ceil

import jinja2 as jj
import utils.message as message
from systemrdl.node import (AddressableNode, AddrmapNode, MemNode, Node,
                            RegfileNode, RegNode, RootNode)


class RTLExporter:

    def __init__(self):
        """
        load jinja environment and basic context
        """
        loader = jj.FileSystemLoader(os.path.join(os.path.dirname(__file__), "templates"))
        self.jj_env = jj.Environment(
            loader=loader,
            undefined=jj.StrictUndefined
        )

        self.context = {
            'addr_width': 64,
            'data_width': 32,
            'RegNode': RegNode,
            'RegfileNode': RegfileNode,
            'AddrmapNode': AddrmapNode,
            'MemNode': MemNode,
            'isinstance': isinstance,
            'get_comp_addr': self._get_comp_addr,
            'use_abs_addr': self._use_abs_addr,
            'dec_addr_bit': self._dec_addr_bit,
            'is_aligned': self._is_aligned,
            'get_forward_num': self._get_forward_num,
            'get_rtl_name': self._get_rtl_name,
            'use_forward_ff': self._use_forward_ff,
            'use_backward_ff': self._use_backward_ff,
            'remain_bit': self._remain_bit,
            'get_property': self._get_property,
            'get_abs_addr': self._get_abs_addr
        }

    def export_rtl_new(self, top_node: Node, dir: str):
        """
        traverse all addrmap and generate all regmst and regdisp modules in pre-order

        Parameter
        ---------
        `top_node` :
        `path` :
        """
        # if it's the root node, skip to the top addrmap
        if isinstance(top_node, RootNode):
            top_node = top_node.top

        # if it's the top addrmap, generate a regmst module
        if isinstance(top_node, AddrmapNode) and top_node.get_property("hj_genmst"):
            update_context = {
                'mst_node': top_node
            }
            self.context.update(update_context)

            template = self.jj_env.get_template("regmst_template.jinja")

            stream = template.stream(self.context)
            stream.dump(os.path.join(dir,  "%s.v" % (self._get_rtl_name(top_node))))

        for child in top_node.children(unroll=True, skip_not_present=False):
            if isinstance(child, AddrmapNode) and child.get_property("hj_gendisp"):
                update_context = {
                    'disp_node': child
                }
                self.context.update(update_context)

                template = self.jj_env.get_template("regdisp_template.jinja")

                stream = template.stream(self.context)
                stream.dump(os.path.join(dir,  "%s.v" % (self._get_rtl_name(child))))

                self.export_rtl_new(child, dir)

    def _get_rtl_name(self, node:Node):
        return node.get_property("rtl_module_name")

    def _get_forward_num(self, node:AddrmapNode):
        # only for regdisp
        if not node.get_property("hj_gendisp") is True:
            message.error("addrmap %s is not recognized as a regdisp module" % (node.get_path()))
            sys.exit(1)

        return node.get_property("forward_num")

    def _get_abs_addr(self, base_node:AddressableNode, offset=0, byte_step=1, suffix="62'h"):
        return  "%s%x" % (suffix, base_node.absolute_address // byte_step + offset)

    def _use_abs_addr(self, node:Node):
        return node.get_property("hj_use_abs_addr")

    def _get_property(self, node:Node, prop_name):
        return node.get_property(prop_name)

    def _is_aligned(self, node:AddressableNode):
        # whether the forwarding module of regdisp is aligned to its absolute address
        return node.absolute_address % (2 ** ceil(log(node.total_size, 2))) == 0

    def _get_comp_addr(self, node:AddressableNode):
        """
        get compressed address expressions to simplify implementation of decoder
        case statement in RTL code.
        example: 62'h130, 62'h131, ..., 62'h13f -> 62'h13?
        """
        start_addr = node.absolute_address // (self.context["data_width"] // 8)
        end_addr = (node.absolute_address + node.size) // (self.context["data_width"] // 8)

        ptr_addr = start_addr
        comp_addr_expr = []
        prefix = "{}'h".format(self.context["addr_width"] - int(log(self.context["data_width"] // 8, 2)))

        while ptr_addr < end_addr:
            step = 1

            while ptr_addr % (16 ** step) == 0 and ptr_addr + (16 ** step) <= end_addr:
                step += 1

            temp = ptr_addr + 16 ** step - ptr_addr % (16 ** step) - 1

            while ptr_addr <= temp:
                comp_addr_expr.append("%s%x%s" % (prefix, ptr_addr >> (4 * (step - 1)), "?" * (step - 1)))
                ptr_addr += 16 ** (step - 1)
                if ptr_addr + (16 ** (step - 1)) > end_addr:
                    break

        return comp_addr_expr

    def _dec_addr_bit(self):
        # return list with 2 elements: msb, lsb
        return [
            self.context["addr_width"] - 1,
            int(log(self.context["data_width"] // 8, 2))
        ]

    def _use_backward_ff(self, node:AddrmapNode):
        return 1 if node.get_property("hj_use_backward_ff") else 0

    def _use_forward_ff(self, node:AddrmapNode):
        forward_ff_param = []

        for child in node.children(unroll=True, skip_not_present=False):
            if child.get_property("hj_use_upstream_ff"):
                forward_ff_param.append("1'b1")
            else:
                forward_ff_param.append("1'b0")

        return forward_ff_param

    def _remain_bit(self, node:AddressableNode):
        return ceil(log(node.total_size, 2))