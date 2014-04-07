%-------------------------------------------------------------------------
% FILE: slam.m - works!!
% AUTH: B. Green
% DATE: 08/11/06
% DESC: Implements the SLAM algorithm based on a robot model and sensor 
%       data from Nebot.
%-------------------------------------------------------------------------

clear all; clc;
load('data_set');
load('beac_juan3.mat');
landmarks=estbeac; clear estbeac; % true landmark positions (measured w/GPS sensor)

%------------------------INITIALIZE DATA----------------------------------
% Vehicle constants
L=2.83;     % distance between front and rear axles
h=0.76;     % distance between center of rear axle and encoder
b=0.5;      % vertical distance from rear axle to laser
a=3.78;     % horizontal distance from rear axle to laser

% EKF components used in multiple functions
global xest Pest A Q W
global numStates k

xest = zeros(3,1);  % state matrix
Pest = zeros(3,3);  % covariance matrix

numStates=3;        % initially, there are no landmarks

A = zeros(3,3);                 % process model jacobian
W = eye(3);                     % process noise jacobian
Q = [.49   0   0; 0 .49 0; 0 0 (7*pi/180)^2];
Jh = zeros(2,3);                % sensor model jacobian
K = zeros(3,3);                 % kalman gain

To = min([TimeGPS(1),Time_VS(1),TimeLaser(1)]); % data starts being collected at 45 secs for some reason??
Time = Time - To;
t=Time(1);
tfinal = 112;   % there is 112 seconds worth of data
k=1;            % loop iteration counter

% initialize estimates
xest(1,1) = GPSLon(1);      % x position of vehicle
xest(2,1) = GPSLat(1);      % y position of vehicle
xest(3,1) = -126*pi/180;    % phi of vehicle
Pest(:,:) = [0.1, 0, 0; 0, 0.1, 0; 0, 0, 15*pi/180];

% initial inputs
alpha = Steering(1);    % measured steering angle
Ve = Velocity(1);       % measured velocity at back wheel
Vc = Velocity(1) / (1 - (h/L)*tan(alpha));  % measured velocity transformed to vehicle center
%-------------------------------------------------------------------------

disp('Running through Kalman filter...');

%---------------------EXTENDED KALMAN FILTER------------------------------
while t<tfinal
    
    k=k+1;
    t=Time(k);
    dt=t-Time(k-1);
    
    %+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    % PART 1: ENTER IN EQUATIONS FOR PROCESS MODEL
    %+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    % Calculate time update matrices (prediction step of kalman filter)
    % Vc and alpha are updated after prediction...therefore, Vc is Vc(k-1) & alpha is alpha(k-1)
    phi = xest(3,k-1);  % so I don't have to type in xest(3,k-1) for every phi below
    xest(1,k) = ??;     % x prediction
    xest(2,k) = ??;     % y prediction
    xest(3,k) = ??;     % phi prediction
    xest(3,k) = normalizeAngle(xest(3,k));      % keep phi between -180 and 180 degrees
    
    %+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    % END OF PART 1
    %+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    % landmarks are assumed to be static, i.e. pi(k) = pi(k-1)         
    if(numStates>3)
        for i=4:numStates
            xest(i,k)= xest(i,k-1);
        end
    end
    
    %+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    % PART 2: ENTER IN EQUATIONS FOR JACOBIAN OF PROCESS MODEL
    %+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    % Calculate Jacobian A based on vehicle model (df/dx)
    A(1,1)=??; A(1,2)=??; A(1,3)=??;
    A(2,1)=??; A(2,2)=??; A(2,3)=??; 
    A(3,1)=??; A(3,2)=??; A(3,3)=??;
    % rest of A (which is just 2 null matrices and 1 identity) is added in new_state function
        
    % Calculate prediction for covariance matrix
    Pest = ??;

    %+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    % END OF PART 2
    %+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    % Check to see if new velocity and steering measurements are available
    if Sensor(k)==2   % encoders are sensor #2
        Ve = Velocity(Index(k));
        alpha = Steering(Index(k));
        Vc = Ve / (1 - (h/L)*tan(alpha));
    end
    
    % Check to see if new laser data is available    
    if (Sensor(k)==3 & t>1)   % SICK is sensor #3
        
        % from a single 180 degree scan, determine # of landmarks & center of each landmark
        [rangeArray bearingArray] = getLandmarkCenter(Laser(Index(k),:), Intensity(Index(k),:));
        
        zlaser=[rangeArray; bearingArray];          % range/bearing data in observation model format
        numLandmarks = size(rangeArray,2);          % number of LMs captured in a single scan
        
              
        for i=1:numLandmarks                            % for i = 1 to # of landmakrs picked up in single scan
            if(numStates==3)                            % if 1st observed landmark, update state and covariance
                new_state(zlaser(:,i));                 % add new state (i.e. increase all matrix sizes)
                numStates = numStates + 2;              % increase number of states by 2 (1 for xi, 1 for yi)
                [xest,Pest] = updateNew(zlaser(:,i));   % update state and covariance
            else                                        % not 1st landmark -> check to make sure no LMs in range
                [dist,index]=nearby_LMs(zlaser(:,i));   % dist from observation to already incorporated LMs (< 3m)
                min_dist = 2;                           % minimum distance between landmark and observation
                if dist>min_dist                        % if dist to nearby_LM is > "min_dist", add observation as new LM
                    new_state(zlaser(:,i));             % add new state (i.e. increase all matrix sizes)
                    numStates = numStates + 2;          % increase number of states by 2 (1 for xi, 1 for yi)
                    [xest,Pest] = updateNew(zlaser(:,i));               % update state and covariance
                else                                                    % else find closest LM and associate
                    closest = 4 + 2*(index-1);                          % find LM which is closest to observation
                    [xest,Pest] = updateExisting(zlaser(:,i),closest);  % update state and covariance
                end
            end
        end
    end
end

% Plot results
figure; hold on;
plot(GPSLon(1:560),GPSLat(1:560));          % robot position (true)
plot(xest(1,1:k),xest(2,1:k),'g');          % robot position (model)
plot(landmarks(:,1),landmarks(:,2),'*');    % landmark position (true)
for i=4:2:numStates
    plot(xest(i,k),xest(i+1,k),'r*');
end
legend('robot position (true)','robot position (slam)','landmark position (true)','landmark position (slam)');
xlabel('x [meters]'); ylabel('y [meters]');
axis([-10 20 -25 20]);