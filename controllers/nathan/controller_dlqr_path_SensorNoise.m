function u = controller_dlqr_path_SensorNoise(obj, t, x)
% Insert Sensor Noise
mean=0;
std=sqrt(1);
% w= random('norm', mean, std);
w = randn(8,1);
x=x+w;

dof = obj.nDof;
nAct = obj.nAct;

params = obj.controlParams;

% Get the desired state along the trajectory at the given time
t_index = min(find(params.time > t));
if isempty(t_index)
    % If the current time exceeds the lenght of the trajectory, just use
    % the last given state of the trajectory
    t_index = length(params.time);
end

% Desired state
xd = params.states(:, t_index);

if t_index <= size(params.control, 2)
    ud = params.control(:, t_index);
else
    ud = params.control(:,end);
end

% Linearize about desired trajectory position
[A,B] = obj.discretizeLinearizeQuadrotorload(0.1, xd, ...
    ud);

K = dlqr(A,B, 5*eye(dof), eye(nAct));

u = -K*(x-xd) + (obj.mQ + obj.mL)*obj.g/2*ones(2,1);

end