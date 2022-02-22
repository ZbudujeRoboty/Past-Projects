% 5 - osiowy robot
% kinematyka odwrotna
% operacja pick and place
% przebiegi przemieszczen, predkosci i przyspieszen
% rysunek toru
%
% by Jan Brzyk

clear all;
close all;
% operacja pick and place
zmie = [1,0,0,0;0,1,0,0;0,0,1,0;0,0,0,1;1,0,0,0,]; %tabela zmiennosci
% 9 punktów toru ruchu (Px Py Pz fi2 fi3)
P1 = [0.3, 0.3, 0.7, 45, 0];    %polozenie poczatkowe
P2 = [0.3, 0.3, 0.6, 45, 0];    %uniesienie
P3 = [-0.1, 0.25, 0.6, 0, 0];   %przeniesienie
P4 = [-0.2, 0.1, 0.6, 0, 0];    %przeniesienie
P5 = [-0.3, -0.3, 0.6, 0, 120]; %przenoszenie -> opuszczenie
P6 = [-0.3, -0.3, 0.7, 0, 120]; %opuszczenie + zwolnienie przemiotu
P7 = [0.1, -0.2, 0.6, 0, 0];    %powrot
P8 = [0.2, -0.1, 0.6, 0, 0];    %powrot
P9 = P1;                        %polozenie poczatkowe

%J = Q_1 D_2 A_3 Q_4 Q_5 R P Y fi1
J1 = kin_inv(P1(1),P1(2),P1(3),P1(4),P1(5));
J2 = kin_inv(P2(1),P2(2),P2(3),P2(4),P2(5));
J3 = kin_inv(P3(1),P3(2),P3(3),P3(4),P3(5));
J4 = kin_inv(P4(1),P4(2),P4(3),P4(4),P4(5));
J5 = kin_inv(P5(1),P5(2),P5(3),P5(4),P5(5));
J6 = kin_inv(P6(1),P6(2),P6(3),P6(4),P6(5));
J7 = kin_inv(P7(1),P7(2),P7(3),P7(4),P7(5));
J8 = kin_inv(P8(1),P8(2),P8(3),P8(4),P8(5));
J9 = kin_inv(P9(1),P9(2),P9(3),P9(4),P9(5));

prompt = 'Ruch ciagly(c) / z przystankiem(p): '; %wybor uzytkownika
mode = input(prompt,'s');
switch mode
    case 'c' %Ruch ciągły P1-P9 (RAZEM Z WYKREŚLENIEM TORU 3D)
        %Qi = Ji: P1 P2 P3 P4 P5 P6 P7 P8 P9
        Q1_basic = [J1(1),J2(1),J3(1),J4(1),J5(1),J6(1),J7(1),J8(1),J9(1)];
        Q1 = zeros (1, length(Q1_basic));
        for i = 1:length(Q1_basic)    %zmiana zakresu z -180 180 na 0 360
            if Q1_basic(i) < 0 || i == 9   % dla ostatniego elementu i tak dodajemy 360 ze względu na pełen obrót pierwszego członu podczas ruchu
                Q1(i) = Q1_basic(i) + 360; % niestety to działa tylko dla tego konkretnego przypadku, a nie dla ogólnego
            else
                Q1(i) = Q1_basic(i); 
            end
        end
        Q1 = Q1_basic; %TURN THIS LINE ON - TOR 3D / OFF - wykresy predkosci, przyspieszen
        Q2 = [J1(2),J2(2),J3(2),J4(2),J5(2),J6(2),J7(2),J8(2),J9(2)];
        Q3 = [J1(3),J2(3),J3(3),J4(3),J5(3),J6(3),J7(3),J8(3),J9(3)];
        Q4 = [J1(4),J2(4),J3(4),J4(4),J5(4),J6(4),J7(4),J8(4),J9(4)];
        Q5 = [J1(5),J2(5),J3(5),J4(5),J5(5),J6(5),J7(5),J8(5),J9(5)];

        %wektor odstepow czasu (9 pkt - 8 odcinkow)
        T=[0.2,0.17,0.12,0.32,0.2,0.28,0.15,0.35];
        %T=[0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11];
        % zadanie prędkości i przyśpieszenia początkowego i końcowego, obie wartości przyjmujemy jako 0.
        V=[0 0];A=[0 0];

        %planowanie trajektorii z czasem ruchu T (deg -> rad)
        y1 = fun_path(deg2rad(Q1),T,V,A);
        y2 = fun_path(Q2,T,V,A);
        y3 = fun_path(Q3,T,V,A);
        y4 = fun_path(deg2rad(Q4),T,V,A);
        y5 = fun_path(deg2rad(Q5),T,V,A);

        prompt = 'Trajektorie człony kątowe(k) / liniowe(l) / RYSUNEK TORU(r): '; %wybor uzytkownika
        answear = input(prompt,'s');
        switch answear
            case 'k'
                %rysunki trajektorii (złącza kątowe)
                [xt1,vt1,at1,tt1,ti1]=fun_graph(y1,T,0.001,'b','-',zmie,2,1);
                [xt4,vt4,at4,tt4,ti4]=fun_graph(y4,T,0.001,'g','-',zmie,2,1);
                [xt5,vt5,at5,tt5,ti5]=fun_graph(y5,T,0.001,'r','-',zmie,2,1);
            case 'l'
                %rysunki trajektorii (złącza liniowe)
                [xt2,vt2,at2,tt2,ti2]=fun_graph(y2,T,0.001,'c','-',zmie,2,1);
                [xt3,vt3,at3,tt3,ti3]=fun_graph(y3,T,0.001,'m','-',zmie,2,1);
            case 'r'
                %TOR RUCHU 3D
                y1 = fun_path(Q1,T,V,A);   %poprawka y bez radianów
                y2 = fun_path(Q2,T,V,A);
                y3 = fun_path(Q3,T,V,A);
                y4 = fun_path(Q4,T,V,A);
                y5 = fun_path(Q5,T,V,A);
                [xt1,vt1,at1,tt1,ti1]=fun_graph(y1,T,0.001,'b','-',zmie,2,1);
                [xt2,vt2,at2,tt2,ti2]=fun_graph(y2,T,0.001,'c','-',zmie,2,1);
                [xt3,vt3,at3,tt3,ti3]=fun_graph(y3,T,0.001,'m','-',zmie,2,1);
                [xt4,vt4,at4,tt4,ti4]=fun_graph(y4,T,0.001,'g','-',zmie,2,1);
                [xt5,vt5,at5,tt5,ti5]=fun_graph(y5,T,0.001,'r','-',zmie,2,1);
                L = length(xt1);
                rounding = 10;      %ten parametr zalezy od wielkosc xt1 zeby samples wyszlo ok. 150
                samples = fix(L/rounding); %zmniejszenie liczby probek dla wydajnosci
                X_line = zeros(1,length(ti1)+2);
                Y_line = zeros(1,length(ti1)+2);
                Z_line = zeros(1,length(ti1)+2);
                X = zeros(1,samples);
                Y = zeros(1,samples);
                Z = zeros(1,samples);
                for i = 0:length(ti1)+1 %łamana
                    if i==0
                        kin = kin_forw(xt1(1),xt2(1),xt3(1),xt4(1),xt5(1)); 
                    else if i==8
                        kin = kin_forw(xt1(L),xt2(L),xt3(L),xt4(L),xt5(L));
                        else
                            kin = kin_forw(xt1(ti1(i)),xt2(ti1(i)),xt3(ti1(i)),xt4(ti1(i)),xt5(ti1(i))); 
                        end
                    end
                    X_line(i+1) = kin(1);
                    Y_line(i+1) = kin(2);
                    Z_line(i+1) = kin(3);
                end
                j = 1; %dodakowy licznik
                for i = 1:rounding:L-rem(L,rounding)  %krzywa
                    kin = kin_forw(xt1(i),xt2(i),xt3(i),xt4(i),xt5(i)); 
                    X(j) = kin(1);
                    Y(j) = kin(2);
                    Z(j) = kin(3);
                    j = j+1;
                end
                figure;
                plot3(X_line,Y_line,Z_line);
                hold on;
                plot3(X,Y,Z);
                xlabel('X');
                ylabel('Y');
                zlabel('Z');
                title('Tor ruchu');
                axis equal;
                grid on;
                %dlugosci torow ruchu (lamana i krzywa)
                dlugosc_lamana = zeros(1,length(X_line)-1);
                for i = 1:length(dlugosc_lamana)
                    dlugosc_lamana(i) = sqrt((X_line(i+1)-X_line(i))^2+(Y_line(i+1)-Y_line(i))^2+(Z_line(i+1)-Z_line(i))^2);
                end
                dlugosc_krzywa = zeros(1,length(X)-1);
                for i = 1:length(dlugosc_krzywa)
                    dlugosc_krzywa(i) = sqrt((X(i+1)-X(i))^2+(Y(i+1)-Y(i))^2+(Z(i+1)-Z(i))^2);
                end
                dlugosc_lamanej = sum(dlugosc_lamana)
                dlugosc_krzywej = sum(dlugosc_krzywa)
                
            otherwise
                return
        end
        
    case 'p' %ruch z przystankiem P1-P6 P6-P9
        prompt = 'Ruch roboczy(r) / powrotny(p): ';
        move = input(prompt,'s');
        switch move
            case 'r'    %ruch roboczy
                %Qi = Ji: P1 P2 P3 P4 P5 P6
                Q1_basic = [J1(1),J2(1),J3(1),J4(1),J5(1),J6(1)];
                Q1 = zeros (1, length(Q1_basic));
                for i = 1:length(Q1_basic)    %zmiana zakresu z -180 180 na 0 360
                    if Q1_basic(i) < 0
                        Q1(i) = Q1_basic(i) + 360; 
                    else
                        Q1(i) = Q1_basic(i); 
                    end
                end
                Q2 = [J1(2),J2(2),J3(2),J4(2),J5(2),J6(2)];
                Q3 = [J1(3),J2(3),J3(3),J4(3),J5(3),J6(3)];
                Q4 = [J1(4),J2(4),J3(4),J4(4),J5(4),J6(4)];
                Q5 = [J1(5),J2(5),J3(5),J4(5),J5(5),J6(5)];

                %wektor odstepow czasu (6 pkt - 5 odcinkow)
                T=[0.2,0.15,0.14,0.45,0.2]; %roboczy
                % zadanie prędkości i przyśpieszenia początkowego i końcowego, obie wartości przyjmujemy jako 0.
                V=[0 0];A=[0 0];

                %planowanie trajektorii z czasem ruchu T (deg -> rad)
                y1 = fun_path(deg2rad(Q1),T,V,A);
                y2 = fun_path(Q2,T,V,A);
                y3 = fun_path(Q3,T,V,A);
                y4 = fun_path(deg2rad(Q4),T,V,A);
                y5 = fun_path(deg2rad(Q5),T,V,A);

                prompt = 'Trajektorie człony kątowe(k) / liniowe(l): '; %wybor uzytkownika
                answear = input(prompt,'s');
                switch answear
                    case 'k'
                        %rysunki trajektorii (złącza kątowe)
                        [xt1,vt1,at1,tt1,ti1]=fun_graph(y1,T,0.001,'b','-',zmie,2,1);
                        [xt4,vt4,at4,tt4,ti4]=fun_graph(y4,T,0.001,'g','-',zmie,2,1);
                        [xt5,vt5,at5,tt5,ti5]=fun_graph(y5,T,0.001,'r','-',zmie,2,1);
                    case 'l'
                        %rysunki trajektorii (złącza liniowe)
                        [xt2,vt2,at2,tt2,ti2]=fun_graph(y2,T,0.001,'c','-',zmie,2,1);
                        [xt3,vt3,at3,tt3,ti3]=fun_graph(y3,T,0.001,'m','-',zmie,2,1);
                    otherwise
                        return
                end
            case 'p'    %ruch powrotny
                 %Qi = Ji: P6 P7 P8 P9
                Q1_basic = [J6(1), J7(1), J8(1), J9(1)];
                Q1 = zeros (1, length(Q1_basic));
                for i = 1:length(Q1_basic)    %zmiana zakresu z -180 180 na 0 360
                    if Q1_basic(i) < 0 || i == 4
                        Q1(i) = Q1_basic(i) + 360; 
                    else
                        Q1(i) = Q1_basic(i); 
                    end
                end
                Q2 = [J6(2), J7(2), J8(2), J9(2)];
                Q3 = [J6(3), J7(3), J8(3), J9(3)];
                Q4 = [J6(4), J7(4), J8(4), J9(4)];
                Q5 = [J6(5), J7(5), J8(5), J9(5)];

                %wektor odstepow czasu (4 pkt - 3 odcinki)
                T=[0.35,0.2,0.35 ]; %powrotny
                % zadanie prędkości i przyśpieszenia początkowego i końcowego, obie wartości przyjmujemy jako 0.
                V=[0 0];A=[0 0];

                %planowanie trajektorii z czasem ruchu T (deg -> rad)
                y1 = fun_path(deg2rad(Q1),T,V,A);
                y2 = fun_path(Q2,T,V,A);
                y3 = fun_path(Q3,T,V,A);
                y4 = fun_path(deg2rad(Q4),T,V,A);
                y5 = fun_path(deg2rad(Q5),T,V,A);

                prompt = 'Trajektorie człony kątowe(k) / liniowe(l): '; %wybor uzytkownika
                answear = input(prompt,'s');
                switch answear
                    case 'k'
                        %rysunki trajektorii (złącza kątowe)
                        [xt1,vt1,at1,tt1,ti1]=fun_graph(y1,T,0.001,'b','-',zmie,2,1);
                        [xt4,vt4,at4,tt4,ti4]=fun_graph(y4,T,0.001,'g','-',zmie,2,1);
                        [xt5,vt5,at5,tt5,ti5]=fun_graph(y5,T,0.001,'r','-',zmie,2,1);
                    case 'l'
                        %rysunki trajektorii (złącza liniowe)
                        [xt2,vt2,at2,tt2,ti2]=fun_graph(y2,T,0.001,'c','-',zmie,2,1);
                        [xt3,vt3,at3,tt3,ti3]=fun_graph(y3,T,0.001,'m','-',zmie,2,1);
                    otherwise
                        return
                end
            otherwise
                return
        end
    otherwise
        return
end


% Dynamika
prompt = 'Liczyć dynamikę? (t) / (n): '; %wybor uzytkownika
dyn = input(prompt,'s');
if dyn == 't'
    syms d2 a3 d3 d5 m1 m2 m3 m4 m5 az1 az2 az3 az4 az5 vz1 vz2 vz3 vz4 vz5 b I1z I4z q1 q4 q5
    wsp = [0, 0, d2/2, 1;
           a3/2, 0, 0, 1;
           0, 0, -d3, 1;
           0, 0, 0, 1;
           0, 0, 0, 1];
    Js{1} = [I1z/2 0 0 0; 0 I1z/2 0 0; 0 0 -I1z/2 0; 0 0 0 0];
    Js{2} = [(m2*a3^2)/3 0 0 m2*a3/2; 0 0 0 0; 0 0 0 0; m2*a3/2 0 0 m2];
    Js{3} = [0 0 0 0; 0 0 0 0; 0 0 m3*d3^2 -m3*d3; 0 0 -m3*d3 m3];
    Js{4} = [0 0 0 0; 0 0 0 0; 0 0 0 0; 0 0 0 m4];
    %Js{1} = [I4z/2 0 0 0; 0 I4z/2 0 0; 0 0 -I4z/2 0; 0 0 0 0];
    Js{5} = [0 0 0 0; 0 2*m5*b^2 0 0; 0 0 0 0; 0 0 0 m5];
    m = [m1, m2, m3, m4, m5];
    vz = [vz1, vz2, vz3, vz4, vz5];
    az = [az1, az2, az3, az4, az5];
    gg = [0, 0, 9.81, 0];
    
    % model geometryczny
    gp = [q1 0 0 0;
          0 d2 0 0;
          0 d3 a3 0;
          0 0 0 q4;
          q5 d5 0 0];
    zmie = [1 0 0 0;
            0 1 0 0;
            0 0 1 0;
            0 0 0 1;
            1 0 0 0];
    
    % symboliczne wyznaczenie sil napędowych
    F = fun_F(Js,m,vz,az,gg,gp,zmie,wsp);
    F1 = F(1);
    F2 = F(2);
    F3 = F(3);
    F4 = F(4);
    F5 = F(5);
    FS1 = subs(F1, {'m1', 'm2', 'm3', 'm4', 'm5', 'a3', 'd5', 'b', 'I1z','I4z'}, {6, 7, 5, 2, 1, 0.5, 0.4, 0.1, 2, 1});
    FS2 = subs(F2, {'m1', 'm2', 'm3', 'm4', 'm5', 'a3', 'd5', 'b', 'I1z','I4z'}, {6, 7, 5, 2, 1, 0.5, 0.4, 0.1, 2, 1});
    FS3 = subs(F3, {'m1', 'm2', 'm3', 'm4', 'm5', 'a3', 'd5', 'b', 'I1z','I4z'}, {6, 7, 5, 2, 1, 0.5, 0.4, 0.1, 2, 1});
    FS4 = subs(F4, {'m1', 'm2', 'm3', 'm4', 'm5', 'a3', 'd5', 'b', 'I1z','I4z'}, {6, 7, 5, 2, 1, 0.5, 0.4, 0.1, 2, 1});
    FS5 = subs(F5, {'m1', 'm2', 'm3', 'm4', 'm5', 'a3', 'd5', 'b', 'I1z','I4z'}, {6, 7, 5, 2, 1, 0.5, 0.4, 0.1, 2, 1});
    FSS1 = double(subs(FS1, {q1, d2, d3, q4, q5, vz1, vz2, vz3, vz4, vz5, az1, az2, az3, az4, az5}, {xt1, xt2, xt3, xt4, xt5, vt1, vt2, vt3, vt4, vt5, at1, at2, at3, at4, at5}));
    FSS2 = double(subs(FS2, {q1, d2, d3, q4, q5, vz1, vz2, vz3, vz4, vz5, az1, az2, az3, az4, az5}, {xt1, xt2, xt3, xt4, xt5, vt1, vt2, vt3, vt4, vt5, at1, at2, at3, at4, at5}));
    FSS3 = double(subs(FS3, {q1, d2, d3, q4, q5, vz1, vz2, vz3, vz4, vz5, az1, az2, az3, az4, az5}, {xt1, xt2, xt3, xt4, xt5, vt1, vt2, vt3, vt4, vt5, at1, at2, at3, at4, at5}));
    FSS4 = double(subs(FS4, {q1, d2, d3, q4, q5, vz1, vz2, vz3, vz4, vz5, az1, az2, az3, az4, az5}, {xt1, xt2, xt3, xt4, xt5, vt1, vt2, vt3, vt4, vt5, at1, at2, at3, at4, at5}));
    FSS5 = double(subs(FS5, {q1, d2, d3, q4, q5, vz1, vz2, vz3, vz4, vz5, az1, az2, az3, az4, az5}, {xt1, xt2, xt3, xt4, xt5, vt1, vt2, vt3, vt4, vt5, at1, at2, at3, at4, at5}));
    
    % Moc
    PS1 = abs(FSS1.*vt1);
    PS2 = abs(FSS2.*vt2);
    PS3 = abs(FSS3.*vt3);
    PS4 = abs(FSS4.*vt4);
    PS5 = abs(FSS5.*vt5);
    
    figure
    plot(tt1, FSS1, 'b-', tt4, FSS4, 'g-', tt5, FSS5, 'r-', 'LineWidth', 2);
    title('Momenty napędowe (człony obrotowe', 'FontSize', 30);
    ylabel('Moment siły [Nm]', 'FontSize', 25);
    xlabel('Czas [s]');
    grid on
    legend('Człon 1', 'Człon 4', 'Człon 5', 'FontSize', 25);
    
    figure
    plot(tt2, FSS2, 'c-', tt3, FSS3, 'm-', 'LineWidth', 2);
    title('Siły napędowe (człony pryzmatyczne', 'FontSize', 30);
    ylabel('Siłaiły [N]', 'FontSize', 25);
    xlabel('Czas [s]');
    grid on
    legend('Człon 2', 'Człon 3', 'FontSize', 25);
    
    figure
    plot(tt1, PS1, 'b-', tt4, PS4, 'g-', tt5, PS5, 'r-', 'LineWidth', 2);
    title('Moce człnów obrotowych', 'FontSize', 30);
    ylabel('Moc [W]', 'FontSize', 25);
    xlabel('Czas [s]');
    grid on
    legend('Człon 1', 'Człon 4', 'Człon 5', 'FontSize', 25);
    
    figure
    plot(tt2, PS2, 'c-', tt3, PS3, 'm-', 'LineWidth', 2);
    title('Moce członów pryzmatycznych', 'FontSize', 30);
    ylabel('Moc [W]', 'FontSize', 25);
    xlabel('Czas [s]');
    grid on
    legend('Człon 2', 'Człon 3', 'FontSize', 25);
end


disp('Koniec programu');

function wyj = kin_inv (Px, Py, Pz, fi2_deg, fi3_deg)
fi2 = deg2rad(fi2_deg);
fi3 = deg2rad(fi3_deg);
%consts [m]
syms d0 d3 d5 real
%vars
syms q1 d2 a3 q4 q5
%A matrixs
A1 = mA(q1,0,0,0);
A2 = mA(0,d2,0,0);
A3 = mA(0,d3,a3,0);
A4 = mA(0,0,0,q4);
A5 = mA(q5,d5,0,0);
T03 = A1*A2*A3;
T3e = A4*A5;
T0e = T03*T3e;
zmie = [1,0,0,0;0,1,0,0;0,0,1,0;0,0,0,1;1,0,0,0,]; %tabela zmiennosci
Tuproszcz = zam(zmie,T0e,'q'); %uproszczone
p03=T03(:,4); %wektor przemieszczenia członu 3
p0e=T0e(:,4); %wektor przemieszczenia koncowki

%stale geometryczne
d_3 = 0.1;
d_5 = 0.4;
%zmienne zlaczowe - kinematyka prosta
q_1 = 1.2448;
d_2 = 0.3172;
a_3 = 0.4123;
q_4 = 0.7854;
q_5 = 1.3878e-16;
P03=double(subs(p03,{d3, d5, q1, d2, a3, q4, q5},{d_3, d_5, q_1, d_2, a_3, q_4, q_5})); %podstawienie wektor czlonu 3
P0e=double(subs(p0e,{d3, d5, q1, d2, a3, q4, q5},{d_3, d_5, q_1, d_2, a_3, q_4, q_5})); %podstawienie wektor manipulatora
TT=double(subs(T0e,{d3, d5, q1, d2, a3, q4, q5},{d_3, d_5, q_1, d_2, a_3, q_4, q_5})); %podstawienie T manipulatora

fi1 = atan2(Py,Px) + asin(d_5*sin(fi2)/sqrt(Px^2+Py^2));    % kat fi1 jest zalezny, bo mamy 5 osi
Trax = [1 0 0 Px; 0 1 0 0; 0 0 1 0; 0 0 0 1];
Tray = [1 0 0 0; 0 1 0 Py; 0 0 1 0; 0 0 0 1];
Traz = [1 0 0 0; 0 1 0 0; 0 0 1 Pz; 0 0 0 1];
Rotz1 = [cos(fi1) -sin(fi1) 0 0; sin(fi1) cos(fi1) 0 0; 0 0 1 0; 0 0 0 1];
Rotx2 = [1 0 0 0; 0 cos(fi2) -sin(fi2) 0; 0 sin(fi2) cos(fi2) 0; 0 0 0 1];
Rotz3 = [cos(fi3) -sin(fi3) 0 0; sin(fi3) cos(fi3) 0 0; 0 0 1 0; 0 0 0 1];
Tzadana = Trax*Tray*Traz*Rotz1*Rotx2*Rotz3;
Rzadana = Tzadana(1:3,1:3);

% Obliczanie pozycji ramienia (końcówki 3 członu)
pax = Px - d_5*sin(fi1)*sin(fi2);
pay = Py + d_5*cos(fi1)*sin(fi2);
paz = Pz - d_5*cos(fi2);

p03p=subs(p03,d3,d_3); %podstawienie stalych geometrycznych
y1 = pax - p03p(1);
y2 = pay - p03p(2);
y3 = paz - p03p(3);
rozw = solve(y1,y2,y3,[q1 d2 a3]);
Q_1 = eval(rozw.q1);
D_2 = eval(rozw.d2);
A_3 = eval(rozw.a3);
sol_count = length(eval(rozw.q1)); % ilość rozwiązań
out_zone = 0;   % licznik pomocniczy do przekraczania przestrzeni roboczej
for i = length(Q_1):-1:1    % odrzucenie zmiennych poza zakresem
    if D_2(i)<0.1 || D_2(i)>0.5 || A_3(i)<0.1 || A_3(i)>0.5
        Q_1(i) = [];
        D_2(i) = [];
        A_3(i) = [];
        out_zone = out_zone + 1;
    end
end

if out_zone < sol_count
    r03 = T03(1:3,1:3);
    r3e = T3e(1:3,1:3);
    r03p = double(subs(r03,q1,Q_1)); % podstawienie policzonych współrzędnych złączowych 1, 2, 3 pod macierz r03
    Rodwr = r03p'*Rzadana; % z tego liczymy 4 i 5
    Q_4 = -asin(Rodwr(2,3));
    Q_5 = atan2(-Rodwr(1,2),Rodwr(1,1));
    R = atan2(Tzadana(2,1),Tzadana(1,1));
    P = asin(-Tzadana(3,1));
    Y = atan2(Tzadana(3,2),Tzadana(3,3));
    wyj = [rad2deg(Q_1) D_2 A_3 rad2deg(Q_4) rad2deg(Q_5) rad2deg(R) rad2deg(P) rad2deg(Y) rad2deg(fi1)];
    %Sprawdzenie warunków zadania (kinematyka prosta)
    TTT=double(subs(T0e,{d3, d5, q1, d2, a3, q4, q5},{d_3, d_5, Q_1, D_2, A_3, Q_4, Q_5})); %podstawienie T manipulatora
    disp('Zadanie kinematyki odwrotnej policzone');
else
    disp('Pozycja poza przestrzenią roboczą!');
end
end

function wyj = kin_forw(q_1,d_2,a_3,q_4,q_5)
syms d3 d5 real
syms q1 d2 a3 q4 q5
d_3 = 0.1;
d_5 = 0.4;
A1 = mA(q1,0,0,0);
A2 = mA(0,d2,0,0);
A3 = mA(0,d3,a3,0);
A4 = mA(0,0,0,q4);
A5 = mA(q5,d5,0,0);
T03 = A1*A2*A3;
T3e = A4*A5;
T0e = T03*T3e;
p0e=T0e(:,4); %wektor przemieszczenia koncowki
P0e=double(subs(p0e,{d3, d5, q1, d2, a3, q4, q5},{d_3, d_5, deg2rad(q_1), d_2, a_3, deg2rad(q_4), deg2rad(q_5)})); %podstawienie wektor manipulatora
wyj = [P0e(1) P0e(2) P0e(3)];
end