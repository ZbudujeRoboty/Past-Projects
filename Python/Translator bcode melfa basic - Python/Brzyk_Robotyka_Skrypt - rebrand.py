"""
Interim Robotics Project
AGH - University of Science and Technology | Cracow - WIMiR
Study of Mitsubishi Melfa RV-2AJ robot's trajectory
Processing of raster images in order to draw them physically on a piece of paper by a robot

This code translates .gcode commands into MELFA BASIC IV programming language

Hardware:
- Mitsubishi Melfa RV-2AJ robot

Project also requires:
- Inkscape software
- Inkscape MI GRBL extension
- COSIROB software

The current code:
- does not include the capability of changing velocity (always OVRD 100 and g1 f1000)
- supports only one digit delays [s]

Created 2020 by Jan Brzyk
Refreshed 2022 by Jan Brzyk
"""

print("Enter the name of the .gcode file: ")    # eg. kwadrat38_0004.gcode
name = input()                                  # loading the file name from the keyboard
file = open(name, mode="r")                     # input file
# print(file.readlines())                       # listing the input file
wej = file.readlines()                          # list containing lines from the input file
file.close()                                    # closing access to the file
wyj = []              # declaration of the output list
z = 0                 # Z coordinate (write = 5 ; don't write = 10)
z1 = 235.2            # writing offset [mm]
z2 = 240.2            # not writing offset [mm]
SPD = 50              # initial velocity for linear and circular interpolation [mm/s]
A = 3.545             # experimental constant (gcode distance <-> real distance)
ig1 = 0               # G1 geometric command counter, so robot's first move is MOV not MVS, so as not to go beyond area
i = []                          # i table - declaration of auxiliary variables
for i_append in range(0, 12):
    i.append(0)

for line in wej:
    i[0] = i[0] + 1                 # counter of the following for loop
    for i_zero in range(1, 12):     # i table - reset of auxiliary variables
        i[i_zero] = 0
    xcor = ""
    xxcor = 0
    ycor = ""
    yycor = 0
    fcor = ""
    icor = ""
    jcor = ""
    if line[0] == "G":
        if line[1] == "1":
            if line[2] == " ":
                if line[3] == " ":              # G1 - regular straight line move
                    ig1 = ig1 + 1               # increment of ig1 counter
                    if line[4] == "X":
                        for i[1] in range(5, 14):    # text scan
                            if line[i[1]] == " ":
                                break
                            else:
                                xcor = xcor + line[i[1]]    # X coord reading
                    if line[i[1]+1] == "Y":
                        for i[2] in range(i[1]+2, i[1]+11):
                            if (line[i[2]] == "\n") or (line[i[2]] == " "):
                                break
                            else:
                                ycor = ycor + line[i[2]]    # Y coord reading
                    xxcor = round(-A*float(ycor)+340, 4)    # rounding to four decimal places
                    yycor = round(A*float(xcor)-190, 4)
                    wyj.append("P1 = (" + str(xxcor) + ", " + str(yycor) + ", " + str(z) + ", 90, 180, 0)\n")
                    if ig1 == 1:
                        wyj.append("MOV P1\n")              # only first robot's move
                    else:
                        wyj.append("MVS P1\n")
                elif line[3] == "F":
                    for i[3] in range(4, 8):                 # !!! modification required for non-4-digit velocities
                        fcor = fcor + line[i[3]]
                    wyj.append("OVRD 100\n")                # OVRD - rotation velocity [%]
                elif line[3] == "X":                        # G1 X0 YO - homing
                    wyj.append("MOV P0\nHOPEN 1")
        elif line[1] == "2":
            if line[2] == " ":                              # G2 - clockwise move
                prev_xxcor = xxcor                          # point for previous cycle
                prev_yycor = yycor
                for i[4] in range(4, 14):
                    if line[i[4]] == " ":
                        break
                    else:
                        xcor = xcor + line[i[4]]                # X coord reading
                if line[i[4] + 1] == "Y":
                    for i[5] in range(i[4] + 2, i[4] + 12):
                        if line[i[5]] == " ":
                            break
                        else:
                            ycor = ycor + line[i[5]]            # Y coord reading
                    if line[i[5] + 1] == "I":
                        for i[6] in range(i[5]+2, i[5] + 12):
                            if line[i[6]] == " ":
                                break
                            else:
                                icor = icor + line[i[6]]        # I coord reading
                        if line[i[6] + 1] == "J":
                            for i[7] in range(i[6] + 2, i[6] + 12):
                                if line[i[7]] == "\n":
                                    break
                                else:
                                    jcor = jcor + line[i[7]]    # J coord reading
                xxcor = round(-A * float(ycor) + 340, 4)
                yycor = round(A * float(xcor) - 190, 4)
                iicor = round(-A * float(jcor), 4)
                jjcor = round(A * float(icor), 4)
                wyj.append("P2 = (" + str(xxcor) + ", " + str(yycor) + ", " + str(z) + ", 90, 180, 0)\n")   # point
                srx = round(prev_xxcor + iicor, 4)
                sry = round(prev_yycor + jjcor, 4)
                wyj.append("P3 = (" + str(srx) + ", " + str(sry) + ", " + str(z) + ", 90, 180, 0)\n")
                wyj.append("MVR3 P1, P2, P3\n")             # P1 is a actual starting point from previous cycle
                wyj.append("P1 = P2\n")                     # Actual position back to P1
            elif line[2] == "1":                            # G21 - set units to millimeters
                wyj.append("SPD " + str(SPD) + "\nP0 = (355.0, 0.0, 550.0, 0, 90, 0)\nMOV P0\n")
        elif line[1] == "3":                                # G3 - counter-clockwise move
            prev_xxcor = xxcor                              # point for previous cycle
            prev_yycor = yycor
            for i[8] in range(4, 14):
                if line[i[8]] == " ":
                    break
                else:
                    xcor = xcor + line[i[8]]                # X coord reading
            if line[i[8] + 1] == "Y":
                for i[9] in range(i[8] + 2, i[8] + 12):
                    if line[i[9]] == " ":
                        break
                    else:
                        ycor = ycor + line[i[9]]            # Y coord reading
                if line[i[9] + 1] == "I":
                    for i[10] in range(i[9] + 2, i[9] + 12):
                        if line[i[10]] == " ":
                            break
                        else:
                            icor = icor + line[i[10]]       # I coord reading
                    if line[i[10] + 1] == "J":
                        for i[11] in range(i[10] + 2, i[10] + 12):
                            if line[i[11]] == "\n":
                                break
                            else:
                                jcor = jcor + line[i[11]]   # J coord reading
            xxcor = round(-A * float(ycor) + 340, 4)
            yycor = round(A * float(xcor) - 190, 4)
            iicor = round(-A * float(jcor), 4)
            jjcor = round(A * float(icor), 4)
            wyj.append("P2 = (" + str(xxcor) + ", " + str(yycor) + ", " + str(z) + ", 90, 180, 0)\n")  # point
            srx = round(prev_xxcor + iicor, 4)
            sry = round(prev_yycor + jjcor, 4)
            wyj.append("P3 = (" + str(srx) + ", " + str(sry) + ", " + str(z) + ", 90, 180, 0)\n")
            wyj.append("MVR3 P1, P2, P3\n")                 # P1 is a actual starting point from previous cycle
            wyj.append("P1 = P2\n")                         # Actual position back to P1
        elif line[1] == "4":                                # G4 - delay [s] (!!! only works with one digit numbers)
            wyj.append("DLY " + line[4] + "\n")
        elif line[1] == "9":                                # G90 - set relative coordinates
            wyj.append("HCLOSE 1\n")
    elif line[0] == "M":
        if line[1] == "3":                          # M3 - Do not write
            z = z2
            if i[0] != 1:                           # don't execute during first cycle
                wyj.append("MOV P1, -5\n")
        if line[1] == "5":                          # M5 - Do write
            z = z1
            wyj.append("MOV P1, +5\n")
name_output = name + "_output.txt"                   # Name of the output file
file2 = open(name_output, mode="w")                 # Output file
file2.writelines(wyj)                               # Saving data to a file
file2.close()
