#!/usr/bin/env python3

#####################################################################################
# generateTask.py for VHDL task register_file
# Generates random tasks, generates TaskParameters, fill
# entity and description templates
#
# Copyright (C) 2015, 2016 Martin  Mosbeck   <martin.mosbeck@gmx.at> , Gilbert Markum
# License GPL V2 or later (see http://www.gnu.org/licenses/gpl2.txt)
#####################################################################################

from random import randrange
from math import ceil, log

import string
import sys

import json

from jinja2 import FileSystemLoader, Environment

#################################################################

# Temporarily removed:
user_id=sys.argv[1]
task_nr=sys.argv[2]
submission_email=sys.argv[3]
language=sys.argv[4]

params_desc={}
params_entity={}

###################################
## IMPORT LANGUAGE TEXT SNIPPETS ##
###################################

filename ="templates/task_description/language_support_files/lang_snippets_{0}.json".format(language)
with open(filename) as data_file:
    lang_data = json.load(data_file)

##############################
## PARAMETER SPECIFYING TASK##
##############################

# choose width of registers ( from: 8, 16, 32 -> 3 Possibilities )
n = pow(2,randrange(3,6))

# choose N_n ( from 4-8 -> 5 Possibilities )
N_n = randrange(4,9)

# choose special_reg0_size ( from 4-8 -> 5 Possibilities )
special_reg0_size = randrange(4,9)

# choose priority or bypass ( bypass = 0 , priority = 1 )
n_bypass_or_read_priority = randrange(0,2) #(0/1 -> 2 Possibilities)
reg0_bypass_or_read_priority = randrange(0,2) #(0/1 -> 2 Possibilities)


taskParameters=str(n)+"|"+str(N_n)+"|"+str(special_reg0_size)+"|"+str(n_bypass_or_read_priority)+"|"+str(reg0_bypass_or_read_priority)

################################################
# GENERATE PARAMETERS FOR DESCRIPTION TEMPLATE #
################################################

address_width_n  = int(ceil(log(N_n,2)))
address_width_reg0  = int(ceil(log(special_reg0_size,2)))

n_minus_1 = n - 1

if n_bypass_or_read_priority == 0 :	# bypass
	n_bypass_or_read_priority_text = "immediately forwarded"

elif n_bypass_or_read_priority == 1 :	# read priority
	n_bypass_or_read_priority_text = "passed through at the next rising edge of the input CLK signal"

bypass_or_read_priority_text1 = lang_data["bypass_or_read_priority_text1"][n_bypass_or_read_priority]

if n_bypass_or_read_priority == reg0_bypass_or_read_priority :
	reg0_bypass_or_read_priority_text_1 = "This also goes for the special register 0:"
	also = "also"
else :
	reg0_bypass_or_read_priority_text_1 = "On the contrary, for special register 0,"
	also = ""


if reg0_bypass_or_read_priority == 0 :	# bypass
	reg0_bypass_or_read_priority_text_2 = "bypassed immediately"
elif reg0_bypass_or_read_priority == 1 :	# read priority
	reg0_bypass_or_read_priority_text_2 = "passed through at the next rising edge of the input CLK signal"

if reg0_bypass_or_read_priority == 0 and n_bypass_or_read_priority == reg0_bypass_or_read_priority:		# bypass: same as all registers
	bypass_or_read_priority_text2 = lang_data["bypass_or_read_priority_text2"][0]
elif reg0_bypass_or_read_priority == 1 and n_bypass_or_read_priority == reg0_bypass_or_read_priority:	# read priority: same as all registers
	bypass_or_read_priority_text2 = lang_data["bypass_or_read_priority_text2"][1]
elif reg0_bypass_or_read_priority == 0 and n_bypass_or_read_priority != reg0_bypass_or_read_priority:	# bypass: different as all registers
	bypass_or_read_priority_text2 = lang_data["bypass_or_read_priority_text2"][2]
else:																									# read priortiy: different as all registers
	bypass_or_read_priority_text2 = lang_data["bypass_or_read_priority_text2"][3]


bitlabel = ""
for x in range(n - special_reg0_size):
	bitlabel += "\\bitlabel{1}{} & "
bitlabel += "\n"

for x in range(special_reg0_size):
	bitlabel += "\\bitlabel{1}{0"+str(special_reg0_size - 1 - x)+"h} & "
bitlabel = bitlabel[:-2]

reg0_bitheader_bits = ""
for x in range(special_reg0_size):
	reg0_bitheader_bits += str(x) + ", "
if n == special_reg0_size: # avoid printing bitheader bits twice
	reg0_bitheader_bits = reg0_bitheader_bits[:-2]
	reg0_bitheader_bits += "} \\\\ % "
	lower = lang_data["lower"][1]	# used to make the text sound more coherent
else:
	lower = lang_data["lower"][0]

n_minus_reg0_size = n - special_reg0_size

bitbox = ""
for x in range(special_reg0_size):
	bitbox += " & \\bitbox{1}{}"

if N_n > 5:
	dots_or_bitbox = "\\wordbox[]{1}{$\\vdots$} \\\\[-0,25ex]"
elif N_n == 4:
	dots_or_bitbox = ""
elif N_n == 5:
	dots_or_bitbox = "\\begin{rightwordgroup}{02h}\n\\bitbox{"+str(n)+"}{Register 2}\n\\end{rightwordgroup} \\\\"

N_n_minus_2 = N_n - 2
N_n_minus_1 = N_n - 1


############################################
## SET PARAMETERS FOR DESCRIPTION TEMPLATE #
############################################
params_desc.update({"n":n, "address_width_n":str(address_width_n), "address_width_reg0":str(address_width_reg0), "N_n":str(N_n), "n_minus_1":n_minus_1, "special_reg0_size":special_reg0_size, "lower":lower, "n_bypass_or_read_priority_text":n_bypass_or_read_priority_text, "reg0_bypass_or_read_priority_text_1":reg0_bypass_or_read_priority_text_1,"bypass_or_read_priority_text1":bypass_or_read_priority_text1,"bypass_or_read_priority_text2":bypass_or_read_priority_text2, "also":also, "reg0_bypass_or_read_priority_text_2":reg0_bypass_or_read_priority_text_2, "bitlabel":bitlabel, "reg0_bitheader_bits":reg0_bitheader_bits, "n_minus_reg0_size":n_minus_reg0_size, "bitbox":bitbox, "dots_or_bitbox":dots_or_bitbox, "N_n_minus_2":N_n_minus_2, "N_n_minus_1":N_n_minus_1})

params_desc.update({"TASKNR":str(task_nr),"SUBMISSIONEMAIL":submission_email})

##############################
## FILL DESCRIPTION TEMPLATE #
##############################

env = Environment()
env.loader = FileSystemLoader('templates/')
filename ="task_description/task_description_template_{0}.tex".format(language)
template = env.get_template(filename)
template = template.render(params_desc)

filename ="tmp/desc_{0}_Task{1}.tex".format(user_id,task_nr)
with open (filename, "w") as output_file:
    output_file.write(template)


######################################
# SET PARAMETERS FOR ENTITY TEMPLATE #
######################################
params_entity.update({"n":n, "address_width_n":address_width_n, "address_width_reg0":address_width_reg0})

#############################
#   FILL ENTITY TEMPLATE    #
#############################
env = Environment()
env.loader = FileSystemLoader('templates/')
filename ="register_file_template.vhdl"
template = env.get_template(filename)
template = template.render(params_entity)

filename ="tmp/register_file_{0}_Task{1}.vhdl".format(user_id,task_nr)
with open (filename, "w") as output_file:
    output_file.write(template)


###########################
### PRINT TASKPARAMETERS ##
###########################
print(taskParameters)
