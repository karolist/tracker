% Determines the distance between the current observation and every landmark currently 
% in the state vector.  Then returns the distance and index of the closest landmark.
function   [dist,index] = nearby_LMs(zlaser);

    global xest;
    global numStates;
    global k;
    
    
    ii=[4:2:numStates-1];                                   % landmarks in state vector (i.e. if 3 LMs, then ii=4:2:8)
    xx = xest(1,k)+zlaser(1)*cos(zlaser(2)+xest(3,k)-pi/2); % x position of observation
    yy = xest(2,k)+zlaser(1)*sin(zlaser(2)+xest(3,k)-pi/2); % y position of observation
    d=((xx-xest(ii,k)).^2+(yy-xest(ii+1,k)).^2).^0.5;       % row vect of dist from observed LM to LMS in 3m area
                                                            % if 3 LMs, then d = [d1 d2 d3]
    
    [dist,index] = min(d);  % find LM closest to observation and return distance
    clear xx yy;
return;