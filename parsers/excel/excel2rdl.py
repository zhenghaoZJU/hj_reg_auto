from __future__ import annotations
import os.path

import utils.message as message
from .args import EXCEL_REG_FIELD, EXCEL_REG_HEAD

class RDLGenerator:
    """
    Generate SystemRDL based on the register model parsed by `ExcelParser`

    Parameter
    ---------
    `reg_model` : `ExcelParser.parsed_model`
    """
    header_comment = "// generated by HRDA tool\n"

    default_desc = "[Reserved for editing]"

    # each Excel worksheet corresponds to a independent regslv module
    gen_sep_str = "\thj_gendisp = false;\n" \
        "\thj_genslv = true;\n" \
		"\thj_flatten_addrmap = false;\n" \

    srst_def_str = "\tsignal {{\n" \
        "\t\tname = \"{sig_name}\";\n" \
        "\t\tdesc = \"{sig_desc}\";\n" \
        "\t\t{active_mode};\n" \
        "\t}} {sig_name};\n\n"

    sw_type_str = "\t\t\tsw = {sw}; {onread} {onwrite}\n"

    hw_type_str = "\t\t\thw = {hw}; {onwrite}\n"

    srst_ref_str = "\t\t\thj_syncresetsignal = \"{sig_name}\";\n"

    field_str = "\t\tfield {{\n" \
        "\t\t\tname = \"{FieldName}\";\n" \
        "\t\t\tdesc = \"{FieldDesc}\";\n" \
        "{sw_type_str}" \
        "{hw_type_str}" \
        "{srst_ref_str}" \
        "\t\t}} {FieldName}[{FieldBit[0]}:{FieldBit[1]}] = {FieldRstVal};\n\n"

    reg_str = "\t{ext_str}reg {{\n" \
        "\t\tname = \"{RegName}\";\n" \
        "\t\tdesc = \"{RegDesc}\";\n" \
        "\t\tregwidth = {RegWidth};\n\n" \
        "{fields_str}" \
        "\t}} {RegAbbr} @{AddrOffset};\n\n"

    addrmap_str = "addrmap {addrmap_def_name} {{\n" \
        "\tname = \"{addrmap_def_name}\";\n" \
        "\tdesc = \"{addrmap_desc}\";\n\n" \
        "{gen_sep_str}" \
        "{sync_rst_def_str}" \
        "{regs_str}" \
        "}};\n"

    extra_top_str = "addrmap {top_level_name} {{\n" \
        "\thj_gendisp = true;\n" \
        "{sub_maps_str}" \
        "}};\n"

    sub_map_str = "\t{sub_map_def} {sub_map_inst};\n"

    def __init__(self, reg_model:dict[str,list]):
        self.reg_model = reg_model
        self._resize_model()

    def _resize_model(self):
        """
        Refactor the register model parsed by `ExcelParser`
        """
        fkeys = EXCEL_REG_FIELD.keys()
        hkeys = EXCEL_REG_HEAD.keys()

        for addrmap_entry in self.reg_model.values():
            for reg in addrmap_entry:
                fld_num = len(reg["FieldBit"])
                fields = []

                for idx in range(fld_num):
                    reg_field = {}

                    for fkey in fkeys:
                        if fkey == "FieldSyncRstSig":
                            # resize synchronous reset signal names
                            if reg[fkey][idx].lower() == "none":
                                reg_field[fkey] = None
                            else:
                                reg_field[fkey] = reg[fkey][idx].replace(" ", "")
                        else:
                            reg_field[fkey] = reg[fkey][idx]

                    # discard reserved fields
                    if not reg["FieldName"][idx].lower() == "reserved":
                        fields.append(reg_field)

                for rkey in list(reg.keys()):
                    if not rkey in hkeys:
                        reg.pop(rkey)

                reg["Fields"] = fields

    def generate_rdl(self, gen_dir:str, top_name:str, gen_extra_top=False):
        """
        Traverse the parsed model and generate SystemRDL

        Parameter
        ---------
        `gen_dir` : directory to save generated SystemRDL
        `top_name` : 生成的额外包含top addrmap的RDL file名称
        `gen_extra_top` : 是否生成额外包含top addrmap的SystemRDL file

        Return
        ------
        `all_files` : `list`类型, 生成的所有RDL files名称
        """
        all_files = []
        addrmap_def_names = []

        # 当输入全部为Excel Worksheet时, 需要额外生成一个包含top addrmap的RDL file,
        # 此时需要检查生成文件名的重名情况
        # 只有gen_extra_top=True时top_name才会被用到
        if gen_extra_top:
            top_filename = os.path.join(gen_dir, top_name + ".rdl")
            new_name = top_name
            suffix_num = 1

            while os.path.exists(top_filename):
                message.warning("rdl file %s already exists" % (top_filename))
                new_name = top_name + "_%d" %(suffix_num)
                top_filename = os.path.join(gen_dir, new_name + ".rdl")
                suffix_num += 1

            top_name = new_name

        # generate SystemRDL files one by one
        for addrmap_def_name, addrmap_entry in self.reg_model.items():
            regs_str = ""
            srst_sigs_def_str = ""
            srst_sigs = []
            # 生成一个addrmap中所有register例化代码
            for reg in addrmap_entry:
                fields_str = ""
                ext_str = ""

                # 生成一个register所有fields例化代码
                for fld in reg["Fields"]:
                    # synchronous reset signals are in string format split by ','
                    f_srst_sig = fld["FieldSyncRstSig"]
                    if f_srst_sig is not None:
                        srst_ref_str = self.srst_ref_str.format(sig_name=f_srst_sig)

                        for sig in f_srst_sig.split(","):
                            if sig not in srst_sigs:
                                srst_sigs.append(sig)
                                # signal which ends with '_n' is considered active low
                                active_mode = "activelow" if sig.endswith("_n") else "activehigh"
                                srst_sigs_def_str += self.srst_def_str.format(sig_name=sig,
                                                                              sig_desc=self.default_desc,
                                                                              active_mode=active_mode)
                    else:
                        srst_ref_str = ""

                    # reset values in SystemRDL should be in hexdecimal format
                    fld["FieldRstVal"] = hex(fld["FieldRstVal"])

                    # handle software access properties
                    sw = ""
                    rdtype = fld["FieldSwRdType"].lower()
                    wrtype = fld["FieldSwWrType"].lower()
                    # sw read type: na | r | rclr | rset | ruser
                    if rdtype != "na":
                        sw += "r"
                        if rdtype == "r":
                            onread_str = ""
                        else:
                            onread_str = "onread = {};".format(rdtype)

                        # fixed: when onread=ruser,
                        # the register that current field belongs to should be declared external
                        # Ref: SystemRDL2.0 Spec. 9.6.1(j)
                        if rdtype == "ruser":
                            ext_str = "external "
                    else:
                        onread_str = ""
                    # sw write type: na | w | w1 | woset | woclr | wot | wzs | wzc | wzt | wuser
                    if wrtype != "na":
                        if wrtype in ("w", "w1"):
                            sw += wrtype
                            onwrite_str = ""
                        else:
                            sw += "w"
                            onwrite_str = "onwrite = {};".format(wrtype)

                        # fixed: when onwrite=wuser,
                        # the register that current field belongs to should be declared external
                        # Ref: SystemRDL2.0 Spec. 9.6.1(m)
                        if wrtype == "wuser":
                            ext_str = "external "
                    else:
                        onwrite_str = ""

                    sw_type_str = self.sw_type_str.format(sw=sw,
                                                          onread=onread_str,
                                                          onwrite=onwrite_str)

                    # handle hardware access properties: r, w, rw, clr, set
                    hwtype = fld["FieldHwAccType"].lower()
                    if hwtype in ("r", "w", "rw"):
                        hw = hwtype
                        onwrite_str = ""
                    elif hwtype == "clr":
                        hw = "rw"
                        onwrite_str = "hwclr;"
                    elif hwtype == "set":
                        hw = "rw"
                        onwrite_str = "hwset;"
                    else:
                        message.error("unsupported hardware access type %s" % (hwtype))

                    hw_type_str = self.hw_type_str.format(hw=hw,
                                                          onwrite=onwrite_str)

                    fields_str += self.field_str.format(sw_type_str=sw_type_str,
                                                        hw_type_str=hw_type_str,
                                                        srst_ref_str=srst_ref_str,
                                                        **fld)

                # address allocation in SystemRDL should be in hexdecimal format
                reg["AddrOffset"] = hex(reg["AddrOffset"])
                reg_str = self.reg_str.format(ext_str=ext_str,
                                              fields_str=fields_str,
                                              **reg)    # **reg: RegName, RegDesc, RegWidth, RegAbbr, AddrOffset
                regs_str += reg_str

            addrmap_str = self.addrmap_str.format(addrmap_def_name=addrmap_def_name,
                                                  addrmap_desc=self.default_desc,
                                                  gen_sep_str=self.gen_sep_str,
                                                  sync_rst_def_str = srst_sigs_def_str,
                                                  regs_str=regs_str)

            submap_filename = os.path.join(gen_dir, addrmap_def_name + ".rdl")

            # 每个submap RDL只包含一个addrmap, signal定义在addrmap内部,
            # 因此作用域也在addrmap内部, 而非全局
            with open(submap_filename, "w", encoding="utf-8") as f:
                f.write(self.header_comment)
                f.write(addrmap_str)
                message.info("sub-addrmap rdl file saved as %s" % (submap_filename))

            all_files.append(submap_filename)
            addrmap_def_names.append(addrmap_def_name)

        # 为以上生成的这些sub-addrmap套一层root addrmap,
        # 避免compile找不到root addrmap从而只把最后一个解析到的addrmap当作root addrmap
        if gen_extra_top:
            sub_maps_str = ""
            for def_name in addrmap_def_names:
                sub_maps_str += self.sub_map_str.format(
                    sub_map_def=def_name,
                    sub_map_inst=def_name
                )

            extra_top_str = self.extra_top_str.format(
                top_level_name=top_name,
                sub_maps_str=sub_maps_str
            )

            with open(top_filename, "w", encoding="utf-8") as f:
                f.write(self.header_comment)
                f.write(extra_top_str)

                message.info(
                    "extra RDL file including Excel-oriented sub-addrmap instance "
                    "and top addrmap saved as %s" % (top_filename)
                )

            all_files.append(top_filename)

        return all_files