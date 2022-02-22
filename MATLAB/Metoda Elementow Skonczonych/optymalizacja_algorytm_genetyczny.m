% Jan Brzyk 18.01.2022
% Optymalizacja - algorytm genetyczny

clear all
%
l = 10;
h = 2;
F = 1;
nx = 2*l; % dla czasu wykonania <0.5 s *2,5
ny = 2*h;

k = 1; % wagi
l = 1;

% siatka raz!!!, zadana z gory
xi = transpose(repelem([0:l/nx:l], ny+1));
yi_base = 0:h/ny:h;
yi = [];
for i = 1:nx+1
    yi = cat(2, yi, yi_base);
end
yi = transpose(yi);
clear yi_base
tri = delaunay(xi,yi);
DOF = 2*size(xi,1); % Ilosc stopni swobody

ES = size(tri,1); % Ilość elementów skończonych
ci = zeros(1,ES);
%ci = 0.4*ones(1,ES); % wspolczynnik skalujacy
%% Metoda

diary on
warning('off');
%options = optimoptions('ga','Display','iter','Population','bitstring','FunctionTolerance',1e-5,'MaxGenerations',10,'MaxStallGenerations',10,'PopulationSize',500);
options = optimoptions('ga','Display','iter','PopulationType','bitstring','PopulationSize',500);
ci_opt = ga(@fcelu13, length(ci), options);
ci_opt
warning('on');
diary off
%% funkcje

function [a] = fcelu13(ci)
    l = 10;
    h = 2;
    F = 1;
    nx = 2*l; % dla czasu wykonania <0.5 s *5 a nie *2
    ny = 2*h;

    kk = 1; % waga d
    ll = 1; % waga masy
    X = 50; % procent ograniczenia maks masy konstrukcji wzgl masy pocz
    W = 10e9; % kara
    
    % siatka raz!!!, zadana z gory
    xi = transpose(repelem([0:l/nx:l], ny+1));
    yi_base = 0:h/ny:h;
    yi = [];
    for i = 1:nx+1
        yi = cat(2, yi, yi_base);
    end
    yi = transpose(yi);
    clear yi_base
    tri = delaunay(xi,yi);
    DOF = 2*size(xi,1); % Ilosc stopni swobody
    
    %binearyzacja ci od 1e-3 do 1
    for i_ci = 1:length(ci)
        if ci(i_ci) == 0
            ci(i_ci) = 1e-3;
        end
    end
    
    [K, M, Pola, Masa, Masa_pocz] = agreguj_K_i_M_optymalizacja(xi,yi,tri,ci);
    
    % wektor obciażeń f
    f = zeros(DOF,1); 
    f(DOF)=-1; % Y ostatniego węzła (prawy górny róg)
    
    % utwierdzenie - usuwanie odopowednich wierszów i kolumn z macierzy
    % globalnych
    Ku = K;
    Mu = M;
    fu = f;
    % usuniecie kolumn
    Ku(:,1:2*(ny+1)) = [];
    Mu(:,1:2*(ny+1)) = [];
    % usuniecie wierszy
    Ku(1:2*(ny+1),:) = [];
    Mu(1:2*(ny+1),:) = [];
    fu(1:2*(ny+1)) = [];
    
    % u
    uu = inv(Ku)*fu;
    
    % rekonstrukcja u
    scale_factor = 1;
    u = scale_factor*(vertcat(zeros(2*(ny+1),size(uu,2)),uu));
    
    % nowe xi ,yi
    xi_old = xi;
    yi_old = yi;
    for i = 1:(DOF/2)
        xiu(i) = xi_old(i) + u(2*i-1);
        yiu(i) = yi_old(i) + u(2*i);
    end
    xi = xiu';
    yi = yiu';
    % strzałka ugięcia
    d = abs(xi(size(xi,1))-xi_old(size(xi,1)));
    
    % funkcja celu
    a = (d^kk)*(Masa^ll);
    
    % ograniczenia
    %ograniczenie maks masy konstrukcji wzgl masy pocz
    if Masa >= 0.01*X*Masa_pocz
        a = a + W;
    end
    %ograniczenie ci
    if max(ci)>1
        a = a + W;
    end
    if min(ci)<1e-3
        a = a + W;
    end
end

function [K, M, Pola, Masa, Masa_pocz] = agreguj_K_i_M_optymalizacja(xi,yi,tri,ci)
    N = size(tri,1); % ilość Elementów Skończonych
    n = size(xi,1); % ilość punktów węzłowych
    Masa = 0;
    % wlasnosci materialowe
    rho = 2700e-12; % [t/mm^3] gęstość
    E = 70e3; % [MPa] moduł Younga - aluminium
    Ei = zeros(1,N);
    Ei = E*ci;
    v = 0.3; % [-] współczynnik Poissona - aluminium
    %D = (E/((1+v)*(1-2*v)))*[1-v v 0; v 1-v 0; 0 0 0.5*(1-2*v)];    
    Di = zeros(3,3,N);
    
    M = zeros(2*n); % globalna macierz mas
    K = zeros(2*n); % globalna macierz sztywności
    Pola = zeros(1,N); % wektor pól elementów skończonych
    
    for i = 1:N % dla każdego ES
        
        % POLE
        % wierzchołki 
        x1 = xi(tri(i,1));
        x2 = xi(tri(i,2));
        x3 = xi(tri(i,3));
        y1 = yi(tri(i,1));
        y2 = yi(tri(i,2));
        y3 = yi(tri(i,3));
        % boki
        b1 = sqrt((x1-x2)^2 + (y1-y2)^2);
        b2 = sqrt((x2-x3)^2 + (y2-y3)^2);
        b3 = sqrt((x3-x1)^2 + (y3-y1)^2);
        % obwód
        Obw = (b1+b2+b3)/2;
        % pole
        Pola(i) = sqrt(Obw*(Obw-b1)*(Obw-b2)*(Obw-b3));
        
        Di(:,:,i) = (Ei(i)/((1+v)*(1-2*v)))*[1-v v 0; v 1-v 0; 0 0 0.5*(1-2*v)];
        
        % wektor funkcji kształtu tego konkretnego ES
        %syms x y
        %p = [1 x y];
        xiL = [xi(tri(i,1));xi(tri(i,2));xi(tri(i,3))]; % lokalne współrzędne x węzłów tego konkretnego ES
        yiL = [yi(tri(i,1));yi(tri(i,2));yi(tri(i,3))]; % lokalne współrzędne y węzłów tego konkretnego ES
        ME = [ones(3,1) xiL yiL];
        Nex = [0 1 0]*inv(ME);
        Ney = [0 0 1]*inv(ME);
        %Ne = p*inv(ME);
    
        % macierz sztywności tego konkretnego ES
        Be = [Nex(1) 0 Nex(2) 0 Nex(3) 0;
            0 Ney(1) 0 Ney(2) 0 Ney(3);
            Ney(1) Nex(1) Ney(2) Nex(2) Ney(3) Nex(3)];
        %Be = [diff(Ne(1),x) 0 diff(Ne(2),x) 0 diff(Ne(3),x) 0;
        %    0 diff(Ne(1),y) 0 diff(Ne(2),y) 0 diff(Ne(3),y);
        %    diff(Ne(1),y) diff(Ne(1),x) diff(Ne(2),y) diff(Ne(2),x) diff(Ne(3),y) diff(Ne(3),x)];
        A = 0.5*((xiL(2)-xiL(1))*(yiL(3)-yiL(1))-(yiL(2)-yiL(1))*(xiL(3)-xiL(1)));
        Ke = double(Be'*Di(i)*Be*A);
    
        % macierz mas tego konkretnego ES
        m = (1/3)*rho*A;
        m = m*ci(i);
        Masa = Masa + rho*A*ci(i);
        Me = diag([m m m m m m]);
       
        % ODPOWIEDNIE dodawanie wartości do macierzy globalnych
        for ii = 1:3
           for iii = 1:3
               K(2*tri(i,ii)-1,2*tri(i,iii)-1) = K(2*tri(i,ii)-1,2*tri(i,iii)-1) + Ke(2*ii-1,2*iii-1); % [1 0;0 0]
               K(2*tri(i,ii)-1,2*tri(i,iii)) = K(2*tri(i,ii)-1,2*tri(i,iii)) + Ke(2*ii-1,2*iii); % [0 1;0 0]
               K(2*tri(i,ii),2*tri(i,iii)-1) = K(2*tri(i,ii),2*tri(i,iii)-1) + Ke(2*ii,2*iii-1);  % [0 0;1 0]
               K(2*tri(i,ii),2*tri(i,iii)) = K(2*tri(i,ii),2*tri(i,iii)) + Ke(2*ii,2*iii);  % [0 0;0 1]

               M(2*tri(i,ii)-1,2*tri(i,iii)-1) = M(2*tri(i,ii)-1,2*tri(i,iii)-1) + Me(2*ii-1,2*iii-1); % [1 0;0 0]
               M(2*tri(i,ii)-1,2*tri(i,iii)) = M(2*tri(i,ii)-1,2*tri(i,iii)) + Me(2*ii-1,2*iii); % [0 1;0 0]
               M(2*tri(i,ii),2*tri(i,iii)-1) = M(2*tri(i,ii),2*tri(i,iii)-1) + Me(2*ii,2*iii-1);  % [0 0;1 0]
               M(2*tri(i,ii),2*tri(i,iii)) = M(2*tri(i,ii),2*tri(i,iii)) + Me(2*ii,2*iii);  % [0 0;0 1]
           end
        end        
    end
    Masa_pocz = N*rho*A;
end