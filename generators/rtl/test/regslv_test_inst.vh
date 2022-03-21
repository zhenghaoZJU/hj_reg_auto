`ifndef __regslv_test_inst_vh__
`define __regslv_test_inst_vh__
//**************************************Address Definition Here***************************************//
`define test_1_inst_REG1_SW_RW 64'h0//internal
`define test_1_inst_REG2_SW_W 64'h4//internal
`define test_1_inst_REG3_HW 64'h8//internal
`define test_1_inst_REG4_PRECEDENCE 64'hc//internal
`define test_1_inst_REG5_SINGLEPULSE 64'h10//internal
`define test_1_inst_REG6_SW_ACC_MOD 64'h14//internal
`define test_1_inst_REG1_SW_R_alias 64'h100//internal
`define test_1_inst_REG2_SRST_alias 64'h104//internal
`define test_2_inst_shared_2 64'h108//internal
`define test_3_inst_shared_3 64'h10c//internal
`define  64'h200//external
`define  64'h204//external
`define  64'h208//external
`define  64'h20c//external
`define  64'h210//external
`define  64'h214//external
`define  64'h218//external
`define  64'h21c//external
`define  64'h220//external
`define  64'h224//external
`define  64'h228//external
`define  64'h22c//external
`define  64'h230//external
`define  64'h234//external
`define  64'h238//external
`define  64'h23c//external
`define  64'h240//external
`define  64'h244//external
`define  64'h248//external
`define  64'h24c//external
`define  64'h250//external
`define  64'h254//external
`define  64'h258//external
`define  64'h25c//external
`define  64'h260//external
`define  64'h264//external
`define  64'h268//external
`define  64'h26c//external
`define  64'h270//external
`define  64'h274//external
`define  64'h278//external
`define  64'h27c//external
`define  64'h280//external
`define  64'h284//external
`define  64'h288//external
`define  64'h28c//external
`define  64'h290//external
`define  64'h294//external
`define  64'h298//external
`define  64'h29c//external
`define  64'h2a0//external
`define  64'h2a4//external
`define  64'h2a8//external
`define  64'h2ac//external
`define  64'h2b0//external
`define  64'h2b4//external
`define  64'h2b8//external
`define  64'h2bc//external
`define  64'h2c0//external
`define  64'h2c4//external
`define  64'h2c8//external
`define  64'h2cc//external
`define  64'h2d0//external
`define  64'h2d4//external
`define  64'h2d8//external
`define  64'h2dc//external
`define  64'h2e0//external
`define  64'h2e4//external
`define  64'h2e8//external
`define  64'h2ec//external
`define  64'h2f0//external
`define  64'h2f4//external
`define  64'h2f8//external
`define  64'h2fc//external
`define  64'h300//external
`define  64'h304//external
`define  64'h308//external
`define  64'h30c//external
`define  64'h310//external
`define  64'h314//external
`define  64'h318//external
`define  64'h31c//external
`define  64'h320//external
`define  64'h324//external
`define  64'h328//external
`define  64'h32c//external
`define  64'h330//external
`define  64'h334//external
`define  64'h338//external
`define  64'h33c//external
`define  64'h340//external
`define  64'h344//external
`define  64'h348//external
`define  64'h34c//external
`define  64'h350//external
`define  64'h354//external
`define  64'h358//external
`define  64'h35c//external
`define  64'h360//external
`define  64'h364//external
`define  64'h368//external
`define  64'h36c//external
`define  64'h370//external
`define  64'h374//external
`define  64'h378//external
`define  64'h37c//external
`define  64'h380//external
`define  64'h384//external
`define  64'h388//external
`define  64'h38c//external
`define  64'h390//external
`define  64'h394//external
`define  64'h398//external
`define  64'h39c//external
`define  64'h3a0//external
`define  64'h3a4//external
`define  64'h3a8//external
`define  64'h3ac//external
`define  64'h3b0//external
`define  64'h3b4//external
`define  64'h3b8//external
`define  64'h3bc//external
`define  64'h3c0//external
`define  64'h3c4//external
`define  64'h3c8//external
`define  64'h3cc//external
`define  64'h3d0//external
`define  64'h3d4//external
`define  64'h3d8//external
`define  64'h3dc//external
`define  64'h3e0//external
`define  64'h3e4//external
`define  64'h3e8//external
`define  64'h3ec//external
`define  64'h3f0//external
`define  64'h3f4//external
`define  64'h3f8//external
`define  64'h3fc//external
`define  64'h400//external
`define  64'h404//external
`define  64'h408//external
`define  64'h40c//external
`define  64'h410//external
`define  64'h414//external
`define  64'h418//external
`define  64'h41c//external
`define  64'h420//external
`define  64'h424//external
`define  64'h428//external
`define  64'h42c//external
`define  64'h430//external
`define  64'h434//external
`define  64'h438//external
`define  64'h43c//external
`define  64'h440//external
`define  64'h444//external
`define  64'h448//external
`define  64'h44c//external
`define  64'h450//external
`define  64'h454//external
`define  64'h458//external
`define  64'h45c//external
`define  64'h460//external
`define  64'h464//external
`define  64'h468//external
`define  64'h46c//external
`define  64'h470//external
`define  64'h474//external
`define  64'h478//external
`define  64'h47c//external
`define  64'h480//external
`define  64'h484//external
`define  64'h488//external
`define  64'h48c//external
`define  64'h490//external
`define  64'h494//external
`define  64'h498//external
`define  64'h49c//external
`define  64'h4a0//external
`define  64'h4a4//external
`define  64'h4a8//external
`define  64'h4ac//external
`define  64'h4b0//external
`define  64'h4b4//external
`define  64'h4b8//external
`define  64'h4bc//external
`define  64'h4c0//external
`define  64'h4c4//external
`define  64'h4c8//external
`define  64'h4cc//external
`define  64'h4d0//external
`define  64'h4d4//external
`define  64'h4d8//external
`define  64'h4dc//external
`define  64'h4e0//external
`define  64'h4e4//external
`define  64'h4e8//external
`define  64'h4ec//external
`define  64'h4f0//external
`define  64'h4f4//external
`define  64'h4f8//external
`define  64'h4fc//external
`endif