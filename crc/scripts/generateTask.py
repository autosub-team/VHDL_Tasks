#!/usr/bin/env python3

########################################################################
# generateTask.py for VHDL task crc
# Generates random tasks, generates TaskParameters, fill
# entity and description templates
#
# Copyright (C) 2015 Martin  Mosbeck   <martin.mosbeck@gmx.at>
# License GPL V2 or later (see http://www.gnu.org/licenses/gpl2.txt)
########################################################################

from random import randrange
from bitstring import Bits
from crcGenerator import genCRC
import string
import sys

from jinja2 import FileSystemLoader, Environment

#################################################################

userId=sys.argv[1]
taskNr=sys.argv[2]
submissionEmail=sys.argv[3]
language=sys.argv[4]

paramsDesc={}
paramsEntityCRC={}
paramsEntityFSR={}
paramsTbExam={}

#generate generator and message length
msgLen= randrange(12,25)

genDegree= randrange(5,12)
generator=[]

#make sure generator has at least 3 coefficients, max 6 and is not all ones
while True:
    generator=list(Bits(uint=randrange(0,2**genDegree+1),length=genDegree+1).bin)
    #for a good polynom
    generator[0]="1"
    generator[-1]="1"
    c_cnt= generator.count("1")
    if (c_cnt>=3) and ( c_cnt !=(genDegree+1) ) and (c_cnt<5):
        break



##############################
## PARAMETER SPECIFYING TASK##
##############################

taskParameters=str(msgLen)+"|"+str(genDegree)+"|"+"".join(generator)


############### ONLY FOR TESTING #######################
filename ="tmp/solution_{0}_Task{1}.txt".format(userId,taskNr)
with open (filename, "w") as solution:
    solution.write("For TaskParameters: " + str(taskParameters) + "\n")
    solution.write("FOOBAR")
#########################################################

################################################
# GENERATE PARAMETERS FOR DESCRIPTION TEMPLATE #
################################################
generatorString=[]

last=genDegree

for i in range(0,last+1):

    if (i==last) and (generator[i]=="1"):
        generatorString.append("1")
    elif (i==last-1) and (generator[i]=="1"):
        generatorString.append("x")
    elif (generator[i]=="1") :
        generatorString.append("x^{"+str(last-i)+"}")

generatorString= "+".join(generatorString)
clockCycles=msgLen+3 #clock cycles after which CRC has to be valid

exampleMSG=Bits(uint=randrange(0,2**msgLen),length=msgLen).bin
exampleCRC=genCRC(exampleMSG,generator)

###########################################
# SET PARAMETERS FOR DESCRIPTION TEMPLATE #
###########################################
paramsDesc.update({"CRCWIDTH":str(genDegree),"GENSTRING":generatorString,"MSGLEN":str(msgLen),"GENDEG":str(genDegree),"GENBIN":"".join(generator),"CLOCKCYCLES":clockCycles,"EXAMPLEMSG":exampleMSG,"EXAMPLECRC":exampleCRC})
paramsDesc.update({"TASKNR":str(taskNr),"SUBMISSIONEMAIL":submissionEmail})

#############################
# FILL DESCRIPTION TEMPLATE #
#############################
env = Environment()
env.loader = FileSystemLoader('templates/')
filename ="task_description/task_description_template_{0}.tex".format(language)
template = env.get_template(filename)
template = template.render(paramsDesc)

filename ="tmp/desc_{0}_Task{1}.tex".format(userId,taskNr)
with open (filename, "w") as output_file:
    output_file.write(template)

###########################################
# SET PARAMETERS FOR ENTITY TEMPLATE CRC  #
###########################################
paramsEntityCRC.update({"CRCWIDTH":str(genDegree),"MSGLEN":str(msgLen)})

#############################
#   FILL ENTITY TEMPLATE    #
#############################
env = Environment()
env.loader = FileSystemLoader('templates/')
filename ="crc_template.vhdl"
template = env.get_template(filename)
template = template.render(paramsEntityCRC)

filename ="tmp/crc_{0}_Task{1}.vhdl".format(userId,taskNr)
with open (filename, "w") as output_file:
    output_file.write(template)

###########################################
# SET PARAMETERS FOR ENTITY TEMPLATE FSR  #
###########################################
paramsEntityFSR.update({"CRCWIDTH":str(genDegree)})

#############################
#   FILL ENTITY TEMPLATE    #
#############################
env = Environment()
env.loader = FileSystemLoader('templates/')
filename ="fsr_template.vhdl"
template = env.get_template(filename)
template = template.render(paramsEntityFSR)

filename ="tmp/fsr_{0}_Task{1}.vhdl".format(userId,taskNr)
with open (filename, "w") as output_file:
    output_file.write(template)

##############################################
# SET PARAMETERS FOR EXAM TESTBENCH TEMPLATE #
##############################################
msgExample=Bits(uint=randrange(1,2**msgLen-1),length=msgLen).bin
paramsTbExam.update({"CRCWIDTH":str(genDegree),"MSGLEN":str(msgLen),"MSG_EXAMPLE":msgExample})

#############################
#   FILL EXAM TEMPLATE    #
#############################
env = Environment()
env.loader = FileSystemLoader('exam/')
filename ="testbench_exam_template.vhdl"
template = env.get_template(filename)
template = template.render(paramsTbExam)

filename ="tmp/crc_tb_exam_{0}_Task{1}.vhdl".format(userId,taskNr)
with open (filename, "w") as output_file:
    output_file.write(template)

###########################
### PRINT TASKPARAMETERS ##
###########################
print(taskParameters)
