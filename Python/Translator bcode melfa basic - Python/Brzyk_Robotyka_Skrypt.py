print("Podaj nazwę pliku z Gcodem:")
#nazwa = "kwadrat38_0004.gcode" #wczytywanie nazwy pliku z kodu
nazwa = input()                 #wczytywanie nazwy pliku z klawiatury
file = open(nazwa,mode="r")     #plik wejsciowy
#print(file.readlines())        #wypisanie pliku wejsciowego
wej = file.readlines()          #lista zawierajaca linie z pliku
file.close()                    #zamkniecie dostepu do pliku
wyj=[]                          #deklaracja listy wyjsciowej
z = 0                           #zmieniajaca sie miedzy 5(pisz) a 10(nie pisz) wspolrzedna Z
z1 = 235.2                          #pisz - offset
z2 = 240.2                         #nie pisz - offset
SPD = 50                        #ustawianie poczatkowej predkosci (teoretycznie mm/s)
A = 3.545                       #doswiadczalnie dobrana stala przejscia miedzy wartosciami obliczanymi w gcodzie a realnymi
#UWAGA OBECNIE CALY CZAS TAKA SAMA PREDKOSC i zawsze jest wypisywane ovrd 100 jak jest g1 f1000
ig1=0    #licznik wykonan komendy geometrycznej G1 (zeby pierwszy ruch byl mov a nie mvs, zeby nie wyjsc poza pole robocze robota)
i=0      #licznik wykonan ponizszej petli for
for linia in wej:
    i = i + 1
    i1 = 0          #deklaracja/zerowanie zmiennych pomocniczych
    i2 = 0
    i3 = 0
    i4 = 0
    i5 = 0
    i6 = 0
    i7 = 0
    i8 = 0
    i9 = 0
    i10 = 0
    i11 = 0
    xcor = ""
    xxcor = 0
    ycor = ""
    yycor = 0
    fcor = ""
    icor = ""
    jcor = ""
    if linia[0] == "G":
        if linia[1] == "1":
            if linia[2] == " ":
                if linia[3] == " ": #G1 zwykly ruch po linii prostej
                    ig1=ig1 + 1     #inkrementacja licznika ig1
                    if linia[4] == "X":
                        for i1 in range(5,14): #skan tesktu
                            if linia[i1] == " ":
                                break
                            else:
                                xcor = xcor + linia[i1] #zczytywanie wspolrzednej X do jednej zmiennej xcor
                    if linia[i1+1] == "Y":
                        for i2 in range(i1+2,i1+11):
                            if (linia[i2] == "\n") or (linia[i2] == " "):
                                break
                            else:
                                ycor = ycor + linia[i2] #zczytywanie wspolrzednej Y do jednej zmiennej ycor
                    xxcor = round(-A*float(ycor)+340, 4) #zaokraglenie do 4 miejsca po przecinku
                    yycor = round(A*float(xcor)-190, 4)
                    wyj.append("P1 = (" + str(xxcor) + ", " + str(yycor) + ", " + str(z) + ", 90, 180, 0)\n")
                    if ig1 == 1:
                        wyj.append("MOV P1\n") #tylko przy pierwszym ruchu robota
                    else:
                        wyj.append("MVS P1\n")
                elif linia[3] == "F":
                    #print("G1 F....")
                    for i3 in range(4,8):       #WYMAGANA MODYFIKACJA PRZY NIE 4-cyfrowych PREDKOSCIACH
                        fcor = fcor + linia[i3]
                    wyj.append("OVRD 100\n")    #ovrd 100
                elif linia[3] == "X":           #G1 X0 YO - powrot do pozycji startowej
                    wyj.append("MOV P0\nHOPEN 1")
        elif linia[1] == "2":
            if linia [2] == " ": #G2 ruch wedlug wskazowek zegara
                popxxcor=xxcor #zapisanie do zmiennej wartosci aktualnego punktu z poprzedniego cyklu petli
                popyycor=yycor
                for i4 in range(4,14):
                    if linia[i4] == " ":
                        break
                    else:
                        xcor = xcor + linia[i4]  #zczytywanie wspolrzednej X do jednej zmiennej xcor
                if linia[i4 + 1] == "Y":
                    for i5 in range(i4 + 2, i4 + 12):
                        if linia[i5] == " ":
                            break
                        else:
                            ycor = ycor + linia[i5]  #zczytywanie wspolrzednej Y do jednej zmiennej ycor
                    if linia[i5 + 1] == "I":
                        for i6 in range(i5+2, i5 + 12):
                            if linia[i6] == " ":
                                break
                            else:
                                icor = icor + linia[i6] #zczytywanie wspolrzednej I do zmiennej icor
                        if linia[i6 + 1] == "J":
                            for i7 in range(i6 + 2, i6 + 12):
                                if linia[i7] == "\n":
                                    break
                                else:
                                    jcor = jcor + linia[i7] #zczytywanie wspolrzednej J do zmiennej jcor
                xxcor = round(-A * float(ycor) + 340, 4)
                yycor = round(A * float(xcor) - 190, 4)
                iicor = round(-A * float(jcor), 4)
                jjcor = round(A * float(icor), 4)
                wyj.append("P2 = (" + str(xxcor) + ", " + str(yycor) + ", " + str(z) + ", 90, 180, 0)\n") #punkt koncowy ruchu
                srx = round(popxxcor + iicor, 4)
                sry = round(popyycor + jjcor, 4)
                wyj.append("P3 = (" + str(srx) + ", " + str(sry) + ", " + str(z) + ", 90, 180, 0)\n")
                wyj.append("MVR3 P1, P2, P3\n")     #P1 jest aktulanym punktem poczatkowym wzietym z poprzedniego cyklu
                wyj.append("P1 = P2\n")             #zmiana aktualnego polozenia spowrotem na P1
            elif linia[2] == "1":             #G21 ustaw jednostki na milimetry
                wyj.append("SPD " + str(SPD) + "\nP0 = (355.0, 0.0, 550.0, 0, 90, 0)\nMOV P0\n")
        elif linia[1] == "3": #G3 ruch przeciwnie do wskazowek zegara
            popxxcor = xxcor  #zapisanie do zmiennej wartosci aktualnego punktu z poprzedniego cyklu petli
            popyycor = yycor
            for i8 in range(4,14):
                if linia[i8] == " ":
                    break
                else:
                    xcor = xcor + linia[i8]  #zczytywanie wspolrzednej X do jednej zmiennej xcor
            if linia[i8 + 1] == "Y":
                for i9 in range(i8 + 2,i8 + 12):
                    if linia[i9] == " ":
                        break
                    else:
                        ycor = ycor + linia[i9]  #zczytywanie wspolrzednej Y do jednej zmiennej ycor
                if linia[i9 + 1] == "I":
                    for i10 in range(i9 + 2, i9 + 12):
                        if linia[i10] == " ":
                            break
                        else:
                            icor = icor + linia[i10]  #zczytywanie wspolrzednej I do zmiennej icor
                    if linia[i10 + 1] == "J":
                        for i11 in range(i10 + 2, i10 + 12):
                            if linia[i11] == "\n":
                                break
                            else:
                                jcor = jcor + linia[i11]
            xxcor = round(-A * float(ycor) + 340, 4)
            yycor = round(A * float(xcor) - 190, 4)
            iicor = round(-A * float(jcor), 4)
            jjcor = round(A * float(icor), 4)
            wyj.append("P2 = (" + str(xxcor) + ", " + str(yycor) + ", " + str(z) + ", 90, 180, 0)\n")  #punkt koncowy ruchu
            srx = round(popxxcor + iicor, 4)
            sry = round(popyycor + jjcor, 4)
            wyj.append("P3 = (" + str(srx) + ", " + str(sry) + ", " + str(z) + ", 90, 180, 0)\n")
            wyj.append("MVR3 P1, P2, P3\n")  #P1 jest aktulanym punktem poczatkowym wzietym z poprzedniego cyklu
            wyj.append("P1 = P2\n")  #zmiana aktualnego polozenia spowrotem na P1
        elif linia[1] == "4": #G4 delay - opoznienie UWAGA OPOZNIENIE DZIALA TYLKO NA 1-CYFROWE WARTOSCI 1,2,...,9
            wyj.append("DLY " + linia[4] + "\n")
        elif linia[1] == "9": #G90 ustaw wspolrzedne wzgledne
            wyj.append("HCLOSE 1\n")
    elif linia[0] == "M":
        if linia[1] == "3": #M3 NIE PISZ
            z = z2
            if i != 1:  #nie wykonuj w pierwszym cyklu
                wyj.append("MOV P1, -5\n")
        if linia[1] == "5": #M5 PISZ
            z = z1
            wyj.append("MOV P1, +5\n")
nazwa_wyjscia = nazwa + "_wynik.txt" #nazwa pliku wyjsciowego
file2 = open(nazwa_wyjscia,mode="w") #plik wyjsciowy
file2.writelines(wyj)                #zapis danych do pliku
file2.close()