
%% Add paths
user = 'nathan';
% addpath(genpath([pwd, '/@Quadrotorload']));
addpath(genpath([pwd, '/controllers/']));
addpath(genpath([pwd, '/gen/']));
addpath(genpath([pwd, '/results/']));
addpath(genpath([pwd, '/traj_gen/']));

%% Reset workspace
clear
clc
close all

%% Build quadrotor system
params = struct;
sys = Quadrotorload(params);
sys.controller = @controller;

%% Testcase 1 - Keyhole
% Don't redefine the problem without specifying a new name!!!
TCfolder = 'Testcase_1_keyhole_2m';
% start and goal states and state constraints
x0 = [-12;0;0;0;0;0;0;0];
xF = [0;0;0;0;0;0;0;0];
xU = [2; 2; pi/2; pi/2; 5; 5; 10; 10];
xL = [-13; -13; -xU(3:end)];
% number of time steps
N=80;
% obstacles
O ={Polyhedron('V',[-6 -5.5; -6 xU(2)+0.1; -7 -5.5; -7 xU(2)+0.1]),...
    Polyhedron('V',[-6 -7.5; -6 xL(2)-0.1; -7 -7.5; -7 xL(2)-0.1])};
% initial guess
xinit = zeros(length(xF),N+1);
xinit(1,1:N/2-2) = linspace(x0(1),-7,N/2-2);
xinit(1,N/2-1:N/2+1) = linspace(-7,-6,3);
xinit(1,N/2+2:end) = linspace(-6,xF(1),N/2);
xinit(2,1:N/2-2) = linspace(x0(2),-6.5,N/2-2);
xinit(2,N/2-1:N/2+1) = linspace(-6.5,-6.5,3);
xinit(2,N/2+2:end) = linspace(-6.5,xF(2),N/2);
% trajectory generation
traj = traj_gen_QRL_polyhedron(sys,O,x0,xF,xU,xL,xinit,N,TCfolder);
% Save Testcase specification and traj in .mat file
save(['results\' TCfolder '\workspace.mat'],'N','O','params',...
    'sys','traj','x0','xF','xinit','xL','xU')

%% Testcase 2 - Inverted Pendulum
% Don't redefine the problem without specifying a new name!!!
TCfolder = 'Testcase_2_inverted_pendulum';
% start and goal states and state constraints
x0 = [0;0;0;0;0;0;0;0];
xF = [0;0;pi;0;0;0;0;0];
xU = [2; 2; pi; pi; 5; 5; 10; 10];
xL = [-2; -2; -xU(3:end)];
% number of time steps
N=80;
% obstacles
O ={};
% initial guess
xinit = zeros(length(xF),N+1);
% trajectory generation
traj = traj_gen_QRL_polyhedron(sys,O,x0,xF,xU,xL,xinit,N,TCfolder);
% Save Testcase specification and traj in .mat file
save(['results\' TCfolder '\workspace.mat'],'N','O','params',...
    'sys','traj','x0','xF','xinit','xL','xU')

%% Testcase 3 - Triangles
% % Don't redefine the problem without specifying a new name!!!
% TCfolder = 'Testcase_3_triangles';
% % start and goal states and state constraints
% x0 = [-11;-11;0;0;0;0;0;0];
% xF = [0;0;0;0;0;0;0;0];
% xU = [2; 2; pi/2; pi/2; 5; 5; 10; 10];
% xL = [-13; -13; -xU(3:end)];
% % number of time steps
% N=80;
% % obstacles
% O ={Polyhedron('V',[-2 xU(2)+0.1; -3.5 -6.5; -5 xU(2)+0.1]),...
%     Polyhedron('V',[-4 xL(2)-0.1; -7 -3.5; -10 xL(2)-0.1])};
% % initial guess
% xinit = zeros(length(xF),N+1);
% xinit(1,1:floor(N/3)) = linspace(x0(1),-7,floor(N/3));
% xinit(1,floor(N/3)+1:2*floor(N/3)) = linspace(-7,-3.5,floor(N/3));
% xinit(1,2*floor(N/3)+1:end) = linspace(-3.5,xF(1),N+1-2*floor(N/3));
% xinit(2,1:floor(N/3)) = linspace(x0(2),-2.5,floor(N/3));
% xinit(2,floor(N/3)+1:2*floor(N/3)) = linspace(-2.5,-7.5,floor(N/3));
% xinit(2,2*floor(N/3)+1:end) = linspace(-7.5,xF(2),N+1-2*floor(N/3));
% % trajectory generation
% traj = traj_gen_QRL_polyhedron(sys,O,x0,xF,xU,xL,xinit,N,TCfolder);
% % Save Testcase specification and traj in .mat file
% save(['results\' TCfolder '\workspace.mat'],'N','O','params',...
%     'sys','traj','x0','xF','xinit','xL','xU')

%% Generate trajectory to track
% load trajectory
% time = traj.t;
% states = traj.x;
% control = traj.u;
% sys.controlParams = struct('time',time,'states',states,'control',control);


%% Simulate System
solver = @ode45;
tspan = [0,10];
% x0 = [-10.5;-10.5;0;0;0;0;0;0];
sol = sys.simulate(tspan, x0, solver);
%% Plot

states = sol.y;
time = sol.x;

% compute inputs:
control = [];
for i = 1:length(time)
    control(:,i) = sys.calcControlInput(time(i), states(:,i));
end

figure
subplot(2,2,1);
plot(time, states(1,:),'r',time, states(2,:),'b');
legend('y','z');
xlabel('time (s)');
ylabel('states');
grid on;
subplot(2,2,2);
plot(time, states(3,:),'r',time, states(4,:),'b');
legend('\phi_L','\phi_Q');
xlabel('time (s)');
ylabel('states');
grid on;
subplot(2,2,3);
plot(time, states(5,:),'r',time, states(6,:),'b');
legend('dy','dz');
xlabel('time (s)');
ylabel('states');
grid on;
subplot(2,2,4);
plot(time, states(7,:),'r',time, states(8,:),'b');
legend('d\phi_L','d\phi_Q');
xlabel('time (s)');
ylabel('states');
grid on;

figure
plot(time, control);
legend('F_1', 'F_2');
xlabel('time (s)');
ylabel('inputs');
grid on;

%% Animate
opts.t = time;
opts.x = states;
opts.vid.MAKE_MOVIE = false;
opts.vid.filename = './results/vid1';
sys.animateQuadrotorload(opts);

