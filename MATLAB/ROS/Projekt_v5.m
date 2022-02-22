% Sterownie autonomiczn¹ kosiark¹
% ROS - Gazebo - Matlab
%
% by Jan Brzyk


clear all
close all

ipaddress = 'http://192.168.93.128:11311';
rosinit(ipaddress)
rostopic list
disp('START'); % debug

odom = rossubscriber('/odom');              % £¹czê siê z informacjami odometrycznymi
velocity = rospublisher('/cmd_vel');        % Ustawiam publishera do sterowania silnikami
velocity_msg = rosmessage(velocity);        % Tworzê temat do wysy³ania poleceñ
lida = rossubscriber('/scan');              % £¹czê siê z lidarem

% wymiary robota
H = 0.08;   % wysokoœæ
r = 0.033;  % promieñ

delatedPoints = 0; % pomocnicza zmienna do liczenia skoszonych "kêpek"

disp('Wczytanie mapy...'); % debug
load('mapa3.mat')   % £adujê mapê 
Wolne = [];
Zajete = [];

disp('Dzielenie mapy...'); % debug
for i = 1:length(M)     % Dzielê mapê na wolne i zajête
    if M(3,i) == 0
        Wolne = cat(2,Wolne,M(1:2,i));
    else
        Zajete = cat(2,Zajete,M(1:2,i));
    end
end
WolneTSP = Wolne';

tsp = tsp_ga('xy',WolneTSP,'numIter',1000); % Generujê trasê
tsp = tsp_ga(tsp);
close all

disp('TSP obliczenia...'); % debug
for i = 1:length(tsp.optRoute)
    Trasa(:,i) = Wolne(:,tsp.optRoute(i));
end

Stan = [0;0;0;0;0;0]; % X Y theta, V, dTheta, kosz

zrzut = 0;              % Zmienna lokalna 
Punkt_Zrzutu = [1; 1];  % Punkt zrzutu trawy [m]

odom_data = receive(odom,3); % Zbieram dane odometryczne
Initial = [odom_data.Pose.Pose.Position.X; odom_data.Pose.Pose.Position.Y];
pose_kin = Initial;
orie = odom_data.Pose.Pose.Orientation;
orie = quat2eul([orie.W orie.X orie.Y orie.Z]);
theta = orie(1);
disp('ROS komunikaty z odometrii'); % debug

Stan(1,1) = Initial(1);
Stan(2,1) = Initial(2);
Stan(3,1) = theta;

Trasa(1,:) = Trasa(1,:) + Initial(1); % Kalibracja trasy
Trasa(2,:) = Trasa(2,:) + Initial(2);
Trasa = Trasa';
disp('Kalibracja pozycji pocz¹tkowej...'); % debug

brzuch = 10000;         % pojemnosc kosza na trawe - 10000 to oko³o 400 "kêpek"
zakres_koszenia = 0.2;  % Jak daleko od punktu mapy zaliczy, ¿e skosi³
zakres_zrzutu = 0.5;
zakres_konca = 0.4;
% Ustawiam kontroler
% Look ahead Distance - bo jest w wielu miejscach i bedziemy go debubowaæ
LookAhDisShort = 0.25;      % dla trasy punkt po punkcie i od zbiornika do koszenia
LookAhDisLong = 0.5;        % dla dlugiej podrozy od wypelnienia zbiornika do pkt zrzutu
MaxAnVel = 0.5;             % MaxAngularVelocity
controller = controllerPurePursuit('DesiredLinearVelocity', 0.2, 'LookaheadDistance', LookAhDisShort, 'MaxAngularVelocity', MaxAnVel, 'Waypoints', Trasa);
controller2 = controllerVFH('RobotRadius', 0.15, 'TargetDirectionWeight', 2, 'CurrentDirectionWeight', 2, 'PreviousDirectionWeight', 2, 'UseLidarScan', true);
disp('Ustawienie kontrolerów'); %debug

sampleTime = 0.05;
vizRate = rateControl(1/sampleTime);

Trasa_Temp = []; % zapasowa zmienna ¿eby zapisywaæ przebyt¹ trasê przed napisaniem podczas zape³nienia zbiornika

iteracja = 0;

pos = []; % puste macierze do sterowania
v_log = [];
omega_log = [];

disp('Start g³ównej pêtli'); % debug
while length(Trasa) > 0
    
    iteracja = iteracja + 1;
    
    if zrzut == 1                   % Jeœli zrzucamy
        disp('zrzucamy trawe!');    % debug
        
        % Jeœli dojecha³ do zrzutu
        if ((Stan(1,iteracja)-Punkt_Zrzutu(1))^2 + (Stan(2,iteracja)-Punkt_Zrzutu(2))^2)^0.5 < zakres_zrzutu 
            disp('Dojechal do zrzutu'); % debug
            velocity_msg.Linear.X = 0;  % STOP
            velocity_msg.Angular.Z = 0;
            velocity.send(velocity_msg);
            disp('Silniki off');        % debug
            Trasa = Trasa_Temp;
            WolneTSP = Trasa;           % Przeliczam ca³¹ trasê
            tsp = tsp_ga('xy',WolneTSP,'numIter',1000);
            tsp = tsp_ga(tsp);
            close all
            
            Trasa = [];
            disp('obliczona Trasa TSP dla zrzutu'); % debug
            for i = 1:length(tsp.optRoute)
                Trasa(:,i) = Wolne(:,tsp.optRoute(i));
            end
            Trasa = Trasa';
            
            Trasa(1,:) = Trasa(1,:) + Initial(1);   % Ustawiam now¹ trasê
            Trasa(2,:) = Trasa(2,:) + Initial(2);
            controller = controllerPurePursuit('DesiredLinearVelocity', 0.2, 'LookaheadDistance', LookAhDisShort, 'MaxAngularVelocity', MaxAnVel, 'Waypoints', Trasa);
            
            zrzut = 0; % Ju¿ nie zrzucam
            % Wracamy na trasê
            disp('Nowa trasa policzona, powrot do koszenia'); % debug
        end       
    end
    
    %Sterowanie
    x = Stan(1,iteracja);
    y = Stan(2,iteracja);
    theta = Stan(3,iteracja);
    Robot_Current_Position = [x y theta];
    lidar = receive(lida,3); % dane z lidaru
    scan = lidarScan(lidar.Ranges, [0:0.0175:6.2832]');
    [v,omega] = controller(Robot_Current_Position);
    pos = cat(1, pos, Robot_Current_Position);
    v_log = cat(2, v_log, v);
    omega_log = cat(2, omega_log, omega);
    
    theta_to_go = theta + omega;
    
    steeringDir = controller2(scan, single(theta_to_go));
    
    if steeringDir == 0
        velocity_msg.Linear.X = v;
        velocity_msg.Angular.Z = omega;
        velocity.send(velocity_msg);
    else
        velocity_msg.Linear.X = v;
        velocity_msg.Angular.Z = steeringDir;
        velocity.send(velocity_msg);
    end
    % Koniec sterowania
    
    
    
    % Niesprzê¿ony uk³ad odometria + GPS
    % Co 10 próbkê pobiera absolutn¹ pozycjê, udaje GPSa.
    
    % Kinematyka odwrotna start
    pose_kin_old = pose_kin;
    pose_kin = [odom_data.Pose.Pose.Position.X; odom_data.Pose.Pose.Position.Y];
    dx = pose_kin(1) - pose_kin_old(1);
    dy = pose_kin(2) - pose_kin_old(2);
    velo = sqrt(dx^2 + dy^2);
    
    theta_old = theta;
    orie = odom_data.Pose.Pose.Orientation;
    orie = quat2eul([orie.W orie.X orie.Y orie.Z]);
    theta = orie(1);
    
    dtheta = theta-theta_old;
    
    dalfa1(iteracja+1) = (velo-dtheta*H)/r;
    dalfa2(iteracja+1) = (velo+dtheta*H)/r;
    
    dalfa1(end) = dalfa1(end) + 0*randn(1); % Mo¿liwa do edycji amplituda b³êdów / szumu
    dalfa2(end) = dalfa2(end) + 0*randn(1);
    Left = dalfa1(end);
    Right = dalfa2(end);
    % Kinematyka odwrotna end
    
    if mod(iteracja,10) ~= 0
        
        [velo, dtheta] = forw_kin(dalfa1(end),dalfa2(end));
        Stan(4,iteracja+1) = velo;
        Stan(5,iteracja+1) = dtheta;
        Stan(3,iteracja+1) = Stan(3,iteracja) + dtheta;
        Stan(1,iteracja+1) = Stan(1,iteracja) + velo*cos(Stan(3,iteracja+1));
        Stan(2,iteracja+1) = Stan(2,iteracja) + velo*sin(Stan(3,iteracja+1));
        Stan(6,iteracja+1) = Stan(6,iteracja) + velo*pi*exp(3);

    else % GPS raz na 10 iteracji
        
        odom_data = receive(odom,3); 
        pose = [odom_data.Pose.Pose.Position.X; odom_data.Pose.Pose.Position.Y];
        Stan(1,iteracja+1) = pose(1);
        Stan(2,iteracja+1) = pose(2);
        
        [velo, dtheta] = forw_kin(Left,Right);
        Stan(4,iteracja+1) = velo;
        Stan(5,iteracja+1) = dtheta;
        Stan(3,iteracja+1) = Stan(3,iteracja) + dtheta;
        Stan(6,iteracja+1) = Stan(6,iteracja) + velo;
        
        disp('length(Trasa):');
        disp(length(Trasa)); % debug
        disp('iteracja:');
        disp(iteracja/10); % debug
    end
    
    % Usuwam z trasy skoszone pole
    if zrzut == 0
        
        Odl = Trasa - [Stan(1,end) Stan(2,end)];
        Odl = ( Odl(:,1).^2 + Odl(:,2).^2 ).^0.5;
        Odl(Odl <= zakres_koszenia) = 0;
        Odl(Odl > zakres_koszenia) = 1;
        
        Indice = find(Odl == 0);
        
        Trasa(Indice,:) = []; % usuniecie z trasy miejsc zaznaczonych jako 0 (jako ju¿ przebyte)
        
        % debug start
        if length(Indice) > 0 
            delatedPoints = delatedPoints + 1;
            disp('Usuniêty pkt nr:');
            disp(delatedPoints);
        end
        % debug end
    end
    
    % Sprawdzam woln¹ pojemnoœæ kosza
    if Stan(6,iteracja) > brzuch
        if zrzut == 0
            disp('Jadê do zrzutu'); % debug
            Trasa_Temp = Trasa;
            Trasa = [Stan(1,iteracja) Stan(2,iteracja);     % Nakazujê jazdê do punktu zrzutu
                    Punkt_Zrzutu(1) Punkt_Zrzutu(2)];       % Dwupunktowa trasa od aktualnego punktu do punktu zrzutu
            controller = controllerPurePursuit('DesiredLinearVelocity', 0.2, 'LookaheadDistance', LookAhDisLong, 'MaxAngularVelocity', MaxAnVel, 'Waypoints', Trasa);
        end
        zrzut = 1;
        Stan(6,iteracja+1) = 0;
    end
    
    waitfor(vizRate);
    
end

disp('Koniec petli - koszenie zakonczone'); % debug

Trasa_End = [Stan(1,iteracja) Stan(2,iteracja);
			 0 0];

disp('Wracam do domu'); % debug
controller = controllerPurePursuit('DesiredLinearVelocity', 0.2, 'LookaheadDistance', LookAhDisLong, 'MaxAngularVelocity', MaxAnVel, 'Waypoints', Trasa_End);
while (distanceToGoal >= zakres_konca) % Nie debugowany while - mog¹ byæ problemy z wymiarami macierzy
 odom_data = receive(odom,3);
 pose = odom_data.Pose.Pose.Position;
 x = pose.X;
 y = pose.Y;

 orie = odom_data.Pose.Pose.Orientation; % Pobieram orientacjê
 orie = quat2eul([orie.W orie.X orie.Y orie.Z]); % Przeliczam orientacjê
 theta = orie(1); % Wyci¹gam tê jedn¹, która mnie interesuje

 Robot_Current_Position = [x y theta];
 distanceToGoal = norm(Robot_Current_Position(1:2) - Trasa_End(end,:));

 [v, omega] = controller(Robot_Current_Position);
 pos = cat(1, pos, Robot_Current_Position);

 velo_msg.Linear.X = v;
 velo_msg.Angular.Z = omega;
 velo.send(velo_msg);

 waitfor(vizRate);

end

disp('Dojecha³em do domu!'); % debug
velocity_msg.Linear.X = 0; %STOP
velocity_msg.Angular.Z = 0;
velocity.send(velocity_msg);

% plot scie¿ki
plot(Stan(1,:), Stan(2,:), 'r-', Trasa(:,1), Trasa(:,2), 'k--d', 'LineWidth',3);
title('Trasa', 'FontSize', 26);
xlabel('X [m]');
ylabel('Y [m]');
grid on
ax = gca;
ax.XAxis.FontSize = 20;
ax.YAxis.FontSize = 20;
axis equal

disp('sciezka na wykresie');


rosshutdown                     % Wy³¹cz ROSa

% Funkcja do odometrii
function [velo, dtheta] = forw_kin(Left, Right)

    H = 0.08;
    r = 0.033;
    
    velo = (Left*r + Right*r)/2;
    dtheta = (-Left*r + Right*r)/(2*H);
    
end