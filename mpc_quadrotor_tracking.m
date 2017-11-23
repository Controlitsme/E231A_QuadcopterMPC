%% 
% Code to implement MPC for trajectory tracking of quadrotor position

%% Setting up env
addpath(genpath([pwd, '/controllers/']));
addpath(genpath([pwd, '/gen/']));

%% Reset workspace
clear
clc
static_disp('');
close all
yalmip('clear')

%% Build quadrotor system
params = struct;
sys = Quadrotor(params);

% actual quadrotor system: to simulate model uncertainty
act_sys = sys;
% uncomment the following to include model uncertainties


%% MPC params
% params
params.mpc.Tf = 10;
params.mpc.Ts = .1;
params.mpc.M = params.mpc.Tf/params.mpc.Ts;
params.mpc.N = 10;
% gains
params.mpc.Q = diag([1000,1000,1000,1,1,1]); %100*eye(sys.nDof);
params.mpc.R = 0.001*eye(sys.nAct);
params.mpc.P = params.mpc.Q;    

%% Load reference trajectory
% fixed point reference trajectory
waypoint = [0;0;0;0;0;0];
xref = repmat(waypoint,1,(params.mpc.M+params.mpc.N));
uref = (sys.mQ*sys.g/2)*ones(2,params.mpc.M+params.mpc.N);

% waypoints
% xref = [zeros(sys.nDof,floor(params.mpc.M/2)), repmat([5;5;0;0;0;0],1,params.mpc.M+params.mpc.N-floor(params.mpc.M/2))];
% uref = (sys.mQ*sys.g/2)*ones(2,params.mpc.M+params.mpc.N);

% [xref, uref] = generate_ref_trajectory(sys,params.mpc);

%% Testing the generated reference trajectory
% time = 0:params.mpc.Ts:params.mpc.Tf;
% xtest = xref(:,1);
% for it = 1:(length(time)-1)
%     f0 = act_sys.systemDynamics([],xref(:,it),uref(:,it));
%     [A,B] = act_sys.discretizeLinearizeQuadrotor(params.mpc.Ts, xref(:,it),uref(:,it));
% %     xtestk = sys.systemDynamics(time(it),xtest(:,it),uref(:,it));
%     xtestk = f0+A*(xref(:,it)-xref(:,it))+B*(uref(:,it)-uref(:,it));
%     xtest = [xtest,xtestk];
% end
% figure;
% plot(xtest(1,:),xtest(2,:));
% opts.t = time';
% opts.x = xtest';
% opts.vid.MAKE_MOVIE = false;
% sys.animateQuadrotor(opts);

%% Initial condition
x0 = [-1.5;-1.5;0;0;0;0];
% x0  = xref(:,1);

%% Control 
% system response
sys_response.x = zeros(sys.nDof,params.mpc.M+1);
sys_response.u = zeros(sys.nAct,params.mpc.M);
sys_response.x(:,1) = x0;

% calculating input over the loop
for impc = 1:params.mpc.M
    static_disp('calculting input for T = %.4f\n',impc*params.mpc.Ts);
    
    % optimizing for input
    xk = sys_response.x(:,impc);
    xrefk = xref(:,impc:(impc+params.mpc.N));
    urefk = uref(:,impc:(impc+params.mpc.N));
    ctlk = solve_cftoc(xk,xrefk,urefk,sys,params);
    
    % forward simulation
    f0 = act_sys.systemDynamics([],xrefk(:,1),urefk(:,1));
    [A,B] = act_sys.discretizeLinearizeQuadrotor(params.mpc.Ts, xrefk(:,1),urefk(:,1));
    u = ctlk.uOpt(:,1);
    %
    sys_response.x(:,impc+1) = f0 + A*(xk-xrefk(:,1))+B*(u-urefk(:,1));
    sys_response.u(:,impc) = u;
end


%% plots
time = 0:params.mpc.Ts:params.mpc.Tf;
figure
plot(time', sys_response.x');
legend('y','z', 'phi', 'dy', 'dz', 'dphi');
xlabel('time (s)');
ylabel('states');
grid on; grid minor;

figure;
plot(sys_response.x(1,:),sys_response.x(2,:),'r','linewidth',2);
grid on; grid minor;
xlabel('Y');ylabel('Z');
title('output trajectory');

figure
plot(time(1:end-1), sys_response.u);
legend('F_1', 'F_2');
xlabel('time (s)');
ylabel('inputs');
grid on; grid minor;

keyboard;
%% Animate
opts.t = time';
opts.x = sys_response.x';
opts.td = time';
opts.xd = xref(:,1:params.mpc.M+1)';
opts.vid.MAKE_MOVIE = false;
sys.animateQuadrotor(opts);





