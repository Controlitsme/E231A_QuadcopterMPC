function [fvec,gvec] = quadrotorloadVectorFields(in1,in2)
%QUADROTORLOADVECTORFIELDS
%    [FVEC,GVEC] = QUADROTORLOADVECTORFIELDS(IN1,IN2)

%    This function was generated by the Symbolic Math Toolbox version 7.2.
%    14-Dec-2017 14:23:04

JQ = in2(2,:);
dphiL = in1(7,:);
dphiQ = in1(8,:);
dyL = in1(5,:);
dzL = in1(6,:);
g = in2(6,:);
l = in2(5,:);
lQ = in2(3,:);
mL = in2(4,:);
mQ = in2(1,:);
phiL = in1(3,:);
phiQ = in1(4,:);
t2 = dphiL.^2;
t3 = mL+mQ;
t4 = 1.0./t3;
t5 = sin(phiL);
t6 = phiL-phiQ;
t7 = cos(t6);
t8 = cos(phiL);
fvec = [dyL;dzL;dphiL;dphiQ;-l.*mQ.*t2.*t4.*t5;-g+l.*mQ.*t2.*t4.*t8;0.0;0.0];
if nargout > 1
    t9 = t4.*t7.*t8;
    t10 = 1.0./l;
    t11 = 1.0./mQ;
    t12 = sin(t6);
    t13 = 1.0./JQ;
    gvec = reshape([0.0,0.0,0.0,0.0,-t4.*t5.*t7,t9,-t10.*t11.*t12,-lQ.*t13,0.0,0.0,0.0,0.0,-t4.*t5.*t7,t9,-t10.*t11.*t12,lQ.*t13],[8,2]);
end
