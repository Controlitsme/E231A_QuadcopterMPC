function traj = traj_gen_QRL_polyhedron(obj)
% FUNCTION INPUTS:
x0 = [-12;0;0;0;0;0;0;0];
xF = [0;0;0;0;0;0;0;0];
% xU = inf(8,1);
xU = [2; 2; pi/2; pi/2; 5; 5; 10; 10];
xL = [-13; -13; -xU(3:end)];
uU = [obj.F1max; obj.F2max];
uL = [obj.F1min; obj.F2min];
N = 80;

% initial guess
xinit = zeros(length(xF),N+1);
xinit(1,1:N/2-2) = linspace(x0(1),-7,N/2-2);
xinit(1,N/2-1:N/2+1) = linspace(-7,-6,3);
xinit(1,N/2+2:end) = linspace(-6,xF(1),N/2);
xinit(2,1:N/2-2) = linspace(x0(2),-6.5,N/2-2);
xinit(2,N/2-1:N/2+1) = linspace(-6.5,-6.5,3);
xinit(2,N/2+2:end) = linspace(-6.5,xF(2),N/2);

QR_width = obj.wQ;
QR_height = obj.hQ;
% cable_d = 0.002;
load_r = obj.wL;


% Generate obstacle
% LATER: FUNCTION INPUT
O ={Polyhedron('V',[-6 -5.5; -6 xU(2)+0.1; -7 -5.5; -7 xU(2)+0.1]),...
    Polyhedron('V',[-6 -7.5; -6 xL(2)-0.1; -7 -7.5; -7 xL(2)-0.1])};

%% Generate quadrotor shape (at "zero" position)
QR = Polyhedron('V',[-QR_width/2 0; QR_width/2 0; -QR_width/2 QR_height;...
    QR_width/2 QR_height]);
% C = Polyhedron('V',[-cable_d/2 0; cable_d/2 0; -cable_d/2 obj.l; ...
%     cable_d/2 obj.l]);
% L = Polyhedron('V',[-load_r -load_r; load_r -load_r; -load_r load_r; ...
%     load_r load_r]);
% Load with cable (box around both) - less constraints for faster run time
L = Polyhedron('V',[-load_r -load_r; load_r -load_r; -load_r obj.l; ...
    load_r obj.l]);

%% Generate optimization problem

M = length(O);              % number of obstacles
numConstrObs = zeros(1,M);  % number of constraints to define each obstacle
for m=1:M
    numConstrObs(m) = size(O{m}.H,1);
end
numConstrQR = size(QR.H,1);
% numConstrC = size(C.H,1);
numConstrL = size(L.H,1);
nx = length(xF);        % number of states
nu = length(uU);        % number of inputs

% Define optimization variables
x = sdpvar(nx, N+1);    % states
assign(x,xinit);
u = sdpvar(nu, N);      % control inputs
% Topt = sdpvar(1,N);     % optimal timestep variable over horizon
Topt = sdpvar(1,1);
% dual variables corresponding to the constraints defining the obs.
lambda = sdpvar(sum(numConstrObs),N);
% dual variables ...
mu_QR = sdpvar(M*numConstrQR,N);
% mu_C = sdpvar(M*numConstrC,N);
mu_L = sdpvar(M*numConstrL,N);

% Define 2D rotation matrix
Rot = @(angle) [cos(angle) -sin(angle); sin(angle) cos(angle)];

% A = sdpvar(nx,nx);
% B = sdpvar(nx,nu);
% [A,B]==obj.discrLinearizeQuadrotor(Topt,...
%     zeros(obj.nDof,1),obj.mQ*obj.g*ones(obj.nAct,1)./2)

% Specify cost function and constraints
q1 = 50;                % cost per time unit
q2 = 100;
R = eye(nu);            % cost for control inputs
dmin = 0.6;             % minimum safety distance
cost = 0;
constr = [x(:,1)==x0, x(:,N+1)==xF];
for k = 1:N
    cost = cost + u(:,k)'*R*u(:,k) ...
        + q1*Topt + q2*Topt^2;
    %         + q1*Topt(k) + q2*Topt(k)^2;
    % Currently for the dynamics, an Euler discretization is used
    constr = [constr, xL<=x(:,k)<=xU, uL<=u(:,k)<=uU, ...
        %         x(:,k+1)==x(:,k)+Topt(k)*systemDyn(obj,x(:,k),u(:,k)), ...
        %         0.01<=Topt(k)<=0.375...
        x(:,k+1)==x(:,k)+Topt*systemDyn(obj,x(:,k),u(:,k)), ...
        0.01<=Topt<=0.375...
        ];
    % Include obstacle avoidance constraints
    for m=1:M
        lda_m = lambda(sum(numConstrObs(1:m-1))+1:sum(numConstrObs(1:m)),k);
        mu_QR_m = mu_QR((m-1)*numConstrQR+1:m*numConstrQR,k);
        % mu_C_m = mu_C((m-1)*numConstrC+1:m*numConstrC,k);
        mu_L_m = mu_L((m-1)*numConstrL+1:m*numConstrL,k);
        % QR body
        constr = [constr, ...
            -QR.H(:,2+1)'*mu_QR_m + ...
            (O{m}.H(:,1:2)*(x(1:2,k)+Rot(x(3,k))*[0; obj.l])-...
            O{m}.H(:,2+1))'*lda_m>=dmin, ...
            QR.H(:,1:2)'*mu_QR_m + Rot(x(4,k))'*O{m}.H(:,1:2)'*lda_m==0,...
            mu_QR_m>=zeros(size(mu_QR_m))];
        % Cable
        %         constr = [constr, ...
        %             -C.H(:,2+1)'*mu_C_m + ...
        %             (O{m}.H(:,1:2)*x(1:2,k)-O{m}.H(:,2+1))'*lda_m>=dmin, ...
        %             C.H(:,1:2)'*mu_C_m + Rot(x(3,k))'*O{m}.H(:,1:2)'*lda_m==0,...
        %             mu_C_m>=zeros(size(mu_C_m))];
        % Load
        constr = [constr, ...
            -L.H(:,2+1)'*mu_L_m + ...
            (O{m}.H(:,1:2)*x(1:2,k)-O{m}.H(:,2+1))'*lda_m>=dmin, ...
            L.H(:,1:2)'*mu_L_m + Rot(x(3,k))'*O{m}.H(:,1:2)'*lda_m==0,...
            mu_L_m>=zeros(size(mu_L_m))];
        % additional obstacle constraints
        constr = [constr, ...
            sum((O{m}.H(:,1:2)'*lda_m).^2)<=1, ...
            lda_m>=zeros(size(lda_m))];
    end
end

% Specify solver and solve the optimization problem
options = sdpsettings('verbose', 1, 'solver', 'IPOPT','usex0',1);
opt = optimize(constr, cost, options);
% Assign output variables
% traj.t = cumsum(value(Topt));
traj.t = 0:value(Topt):N*value(Topt);
traj.u = value(u);
traj.x = value(x);
if opt.problem ~= 0
    % infeasible
    traj.t = [];
    traj.x = [];
    traj.u = [];
end

% Plot the resulting trajectory
figure
plot(traj.x(1,:),traj.x(2,:),'x-')
xlabel('y')
ylabel('z')
title('Generated path with obstacle avoidance')
hold on
for m=1:M
    plot(O{m},'alpha',0.5)
end
plot([xL(1) xL(1)],[xL(2) xU(2)],'k','LineWidth',2)
plot([xU(1) xU(1)],[xL(2) xU(2)],'k','LineWidth',2)
plot([xL(1) xU(1)],[xU(2) xU(2)],'k','LineWidth',2)
plot([xL(1) xU(1)],[xL(2) xL(2)],'k','LineWidth',2)

plot(xinit(1,:),xinit(2,:),'r')
for k=1:N+1
    plot(Polyhedron('H',[QR.H(:,1:2)*Rot(traj.x(4,k))',...
        QR.H(:,2+1)+QR.H(:,1:2)*Rot(traj.x(4,k))'*...
        (traj.x(1:2,k)+Rot(traj.x(3,k))*[0; obj.l])]),...
        'color','b','alpha',0)
    plot(Polyhedron('H',[L.H(:,1:2)*Rot(traj.x(3,k))',...
        L.H(:,2+1)+L.H(:,1:2)*Rot(traj.x(3,k))'*traj.x(1:2,k)]),...
        'color','r','alpha',0)
end
axis equal

figure
plot(traj.t,traj.x)
title('States vs. time')
legend('y_L','z_L','\phi_L','\phi_Q','yd_L','zd_L','\phi d_L','\phi d_Q')

figure
plot(traj.t(1:end-1),traj.u)
title('Inputs vs. time')
legend('u_1','u_2')

% Display the amount of time the planned motion would take
disp(['Reaching the target takes ' num2str(traj.t(end)) 's.'])
end

function ddx = systemDyn(obj,x,u)
[fvec,gvec] = obj.quadVectorFields(x);
ddx = fvec + gvec*u;
end