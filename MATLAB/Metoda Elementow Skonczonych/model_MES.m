% Jan Brzyk 19.12.2021
% Model MES
% BELKA UTWIERDZONA + OBCIAZENIE SKUPIONE

function [wynik_dokladny, u, xi, yi, tri] = model_MES(l, h, F, nx, ny)
 
    % wlasnosci materialowe
    rho = 2700e-12; % [t/mm^3] gęstość
    E = 70e3; % [MPa] moduł Younga - aluminium
    v = 0.3; % [-] współczynnik Poissona - aluminium
    D = (E/((1+v)*(1-2*v)))*[1-v v 0; v 1-v 0; 0 0 0.5*(1-2*v)];

    % analitycznie ugiecie
    I = 1*h^3/12; % [mm^4]
    wynik_dokladny = (F*l^3)/(3*E*I); % [mm]

    % siatka
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
    
    % Ke -> agregacja -> K
    [K, M] = agreguj_K_i_M(xi,yi,tri,D,rho);

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
end

% Ke
function [Ke, Me] = generuj_Ke_i_Me(xi,yi,D,rho)
    syms x y
    
    % wektor funkcji kształtu
    p = [1 x y];
    ME = [ones(3,1) xi yi];
    Ne = p*inv(ME);
    
    % macierz sztywności
    Be = [diff(Ne(1),x) 0 diff(Ne(2),x) 0 diff(Ne(3),x) 0;
        0 diff(Ne(1),y) 0 diff(Ne(2),y) 0 diff(Ne(3),y);
        diff(Ne(1),y) diff(Ne(1),x) diff(Ne(2),y) diff(Ne(2),x) diff(Ne(3),y) diff(Ne(3),x)];
    A = 0.5*((xi(2)-xi(1))*(yi(3)-yi(1))-(yi(2)-yi(1))*(xi(3)-xi(1)));
    Ke = double(Be'*D*Be*A);
    
    % macierz mas
    m = (1/3)*rho*A;
    Me = diag([m m m m m m]);
end

% agregacja
function [K, M] = agreguj_K_i_M(xi,yi,tri,D,rho)
    N = size(tri,1); % ilość Elementów Skończonych
    n = size(xi,1); % ilość punktów węzłowych

    M = zeros(2*n); % globalna macierz mas
    K = zeros(2*n); % globalna macierz sztywności
    
    for i = 1:N
        % wektor funkcji kształtu tego konkretnego ES
        syms x y
        p = [1 x y];
        xiL = [xi(tri(i,1));xi(tri(i,2));xi(tri(i,3))]; % lokalne współrzędne x węzłów tego konkretnego ES
        yiL = [yi(tri(i,1));yi(tri(i,2));yi(tri(i,3))]; % lokalne współrzędne y węzłów tego konkretnego ES
        ME = [ones(3,1) xiL yiL];
        Ne = p*inv(ME);
    
        % macierz sztywności tego konkretnego ES
        Be = [diff(Ne(1),x) 0 diff(Ne(2),x) 0 diff(Ne(3),x) 0;
            0 diff(Ne(1),y) 0 diff(Ne(2),y) 0 diff(Ne(3),y);
            diff(Ne(1),y) diff(Ne(1),x) diff(Ne(2),y) diff(Ne(2),x) diff(Ne(3),y) diff(Ne(3),x)];
        A = 0.5*((xiL(2)-xiL(1))*(yiL(3)-yiL(1))-(yiL(2)-yiL(1))*(xiL(3)-xiL(1)));
        Ke = double(Be'*D*Be*A);
    
        % macierz mas tego konkretnego ES
        m = (1/3)*rho*A;
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
end