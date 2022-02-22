clc
clear all
close all
%% Inicjalizacja parametrow wczesniej wyznaczonego przeksztalcenia homograficznego
load('T.mat');
load('obrot_ukl_robota.mat');

%% Wlaczenie systemu wizyjnego
disp('Uruchamiam system wizyjny');
info = imaqhwinfo('winvideo');
dev_info = imaqhwinfo('winvideo',1);
dev_info.SupportedFormats;

vid_obj = videoinput('winvideo',1,'RGB24_640x480');
start(vid_obj)

%% Wlaczenie komunikacji 
disp('Lacze sie z robotem');
s = serial('COM1','BaudRate',9600,'Parity','Even','Stopbits',2,'Terminator',...
    'CR','DataTerminalReady','off','RequestToSend','off','Timeout',30);
fopen(s);

%% Start petli pracy
disp('Test komunikacji');           % Test komunikacji z robotem
fprintf(s,'PRNSTART');
disp('Oczekuje potwierdzenia o gotowisci');
komunikat = fscanf(s)               % Odebranie komunikatu
disp('Rozpoczynam prace');

for i = 1:1
    %% Pobieram zdjecie
    pause(1)
    disp('Nacisnij przycisk, aby pobrac obraz');
    pause
    I = getsnapshot(vid_obj);
    
    %% Analiza obrazu
    disp('Analizuje obraz');
    I_gray = rgb2gray(I);
    I_bw = I_gray < 150;
    for i = 1:200
        for j = 1:120
            I_bw(i,j) = 0;
        end
    end
    I_bw = bwareaopen(I_bw, 500);
    [objects, objects_n] = bwlabel(I_bw, 8);
    feats = regionprops(objects, 'all');
    Centr = feats(1).Centroid;
    Orient = feats(1).Orientation;
    
    wlasnosci_obiektu = feats;
    
    disp('Wyznaczam przeksztalcenie homograficzne');
    %% Homografia
                % Wyznaczenie srodka obiektu
                srodek_pkt = cat(1, wlasnosci_obiektu.Centroid);
                max_os = cat(1, wlasnosci_obiektu.MajorAxisLength);
                min_os = cat(1, wlasnosci_obiektu.MinorAxisLength);
                srodek = cat(1, wlasnosci_obiektu.Centroid);   
                osie = cat(1,wlasnosci_obiektu.Orientation);
                
                % Wyznaczenie orientacji w oparciu o osie obiektu
                wsp_kier = -tand(osie(1,1));

                prosta_x = (srodek(1,1)-100:0.1:srodek(1,1)+100);
                prosta_y = zeros(size(prosta_x));
                for i=1:length(prosta_x)
                    prosta_y(i) = wsp_kier*(prosta_x(i)-srodek(1,1))+srodek(1,2);
                end
                
                % Transformacja z ukladu wspólrzednych piksela do ukladu robota
                wsp_robota_xy = tformfwd(srodek(1,:),T);
                
                % Wyznaczenie kata obrotu ostatniego zlacza robota (stopnie, dokladnosc 5 cyfr)
                obrot_chwytaka = mod(-subs(vpa(osie(1,1)-obrot_ukl_robota,5)),90)
                
                X = wsp_robota_xy(1,1);     %Zapisanie polozenia do osobnych zmiennych
                Y = wsp_robota_xy(1,2);
                
                %% Komunikacja RS232
                disp('Przesylam dane');
                fprintf(s,strcat('PRN', num2str(X)));      % X
                pause(0.5);
                fprintf(s,strcat('PRN', num2str(Y)));      % Y
                pause(0.5);
                fprintf(s,strcat('PRN', num2str(obrot_chwytaka)));  % Orientacja chwytaka
                pause(0.5);                
                disp('Robot sie porusza');
                komunikat = fscanf(s)
                
                %%
                disp('Koncze prace');
           
end

disp('Zamykam polaczenie');
closepreview(vid_obj)
stop(vid_obj)
delete(vid_obj)
clear vid_obj

fclose(s);