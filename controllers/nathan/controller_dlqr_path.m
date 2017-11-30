function u = controller_dlqr_path(obj, t, x)

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
ud = params.control(:, t_index);

% Linearize about desired trajectory position
[A,B] = obj.discretizeLinearizeQuadrotor(0.1, xd, ...
    ud);

K = dlqr(A,B, 5*eye(dof), eye(nAct));

u = -K*(x-xd) + [obj.mQ*obj.g;obj.mQ*obj.g]./2;
end