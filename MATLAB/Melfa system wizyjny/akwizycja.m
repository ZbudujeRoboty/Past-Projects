info = imaqhwinfo('winvideo');          % Dostępne adaptory
dev_info = imaqhwinfo('winvideo',1);    % Informacja o adaptorze 1
dev_info.SupportedFormats;              % Dostępne formaty

vid_obj = videoinput('winvideo',1,'RGB24_640x480'); % Obiekt wideo

imag_n = input('Podaj ilosc zdjec do pobrania: ');

preview(vid_obj)    % Podgląd
start(vid_obj)      % Akwizycja obrazu
                    
for i = 1:imag_n    % Pętla - ile jest obrazków do pobrania
    pause(1)        
    disp('Nacisnij przycisk, aby pobrac obraz');
    pause                               % Użytkownik musi kliknąć przycisk                                      
    obraz = getsnapshot(vid_obj);               % Pobranie obrazka z kamery
    imwrite(obraz,strcat('obrazek',num2str(i),'.bmp'),'bmp');
    disp(strcat('Pobrano obrazek nr ',num2str(i)))
    pause(2)
end

closepreview(vid_obj)   % Zamknięcie podglądu i usunięcie obiektu wideo
stop(vid_obj)
delete(vid_obj)
clear vid_obj