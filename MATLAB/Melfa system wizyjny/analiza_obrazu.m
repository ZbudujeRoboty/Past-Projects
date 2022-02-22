clc
clear all
close all

%imfinfo('test1.jpg')       % Info o obrazie

I = imread('test1.jpg');    % Wczytanie obrazu

imshow(I);                  % Wyswietlenie

[I_ind, I_map] = rgb2ind(I,64);     % RGB -> indeksowany na 64 kolorach
I_gray = ind2gray(I_ind, I_map);    % Indeksowany -> skala szarosci

[hist_n, hist_val] = imhist(I_gray); % Histogram (granice binaryzacji)
%figure
%imhist(I_gray);

user = input('1 - bialy\n2 - osmiornica\n3 - nakretka\n4 - czarny segment gasienicy\n5 - zebatka\n6 - lodka\n7 - fioletowy segment gasienicy\n8 - czerwony\nWybierz przedmiot: ');
switch user
    case 1 % bialy
        N = 2;
        I_bw = (I_gray > 140);
        I_bw = bwareaopen(I_bw, 2000);
    case 2 % osmiornica
        N = 2;
        I_bw = (I_gray > 0)&(I_gray < 41);
        I_bw = bwareaopen(I_bw, 1000);
    case 3 % nakretka
        N = 3;
        I_bw = (I_gray > 0)&(I_gray < 41);
        I_bw = bwareaopen(I_bw, 1000);
    case 4 % czarny segment gasienicy
        N = 4;
        I_bw = (I_gray > 0)&(I_gray < 41);
        I_bw = bwareaopen(I_bw, 1000);
    case 5 % zebatka
        N = 5;
        I_bw = (I_gray > 0)&(I_gray < 41);
        I_bw = bwareaopen(I_bw, 1000);
    case 6 % lodka
        N = 1;
        I_bw = ((I_gray > 39)&(I_gray < 45))|I_gray == 61;
        I_bw = bwareaopen(I_bw, 2000);
    case 7 % fioletowy segment gasienicy
        N = 1;
        I_bw = I_gray==69;
        I_bw = bwareaopen(I_bw, 1000);
    case 8 % czerwony
        N = 1;
        I_bw = I_gray==76;
        I_bw = bwareaopen(I_bw, 1000);
end

%I_bw = (I_gray > 75)&(I_gray < 76); %Binaryzuje91 (do 45)
%I_bw = bwareaopen(I_bw, 1000); %Usuwam wszystkie elementy, ktore maja wiecej niz 5000 pikseli (wartosc arbitrarna)
%figure %sprawdzam jak wyszlo
%imshow(I_bw)
%%
[objcts,objcts_n] = bwlabel(I_bw, 8);   % labeluje obiekty (8 sasiadow)
imtool(objcts)                          % Wyswietlenie z labelami
%%
%disp(objcts_n) %Wyswietlam ilosc znalezionych obiektow
%object = input('Wybierz obiekt: '); %Uzytkownik wybiera sobie obiekt
object = N;                         % Wartosc z switch/case'a
feats = regionprops(objcts,'all');  % Cechy obiektu
Centr = feats(object).Centroid;
Orient = feats(object).Orientation;
Area = feats(object).Area
Box = feats(object).BoundingBox;

figure                              % Obiekt + środek + orientacja
imshow(ismember(objcts,object));
hold on
%plot([Box(1) Box(1) Box(1)+Box(3) Box(1)+Box(3) Box(1)],[Box(2) Box(2)+Box(4) Box(2)+Box(4) Box(2) Box(2)], 'g-', 'LineWidth', 0.5);
plot([Centr(1) Centr(1)+200*cosd(Orient)], [Centr(2) Centr(2)-200*sind(Orient)], 'r*', 'LineWidth', 10);
plot([Centr(1) Centr(1)+200*cosd(Orient)], [Centr(2) Centr(2)-200*sind(Orient)], 'b-', 'LineWidth', 5);