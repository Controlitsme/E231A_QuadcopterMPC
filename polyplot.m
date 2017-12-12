function polyplot(poly, rot trans)

plot(Polyhedron('H',[poly.H(:,1:2)*rot',...
        poly.H(:,2+1)+poly.H(:,1:2)*rot'*trans...
        (traj.x(1:2,k)+Rot(traj.x(3,k))*[0; obj.l])]),...
        'color','b','alpha',0)

end

