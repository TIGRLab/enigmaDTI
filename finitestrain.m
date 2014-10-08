load transform.txt
dirs=load('/projects/spins/qc/ENIGMA/dirs_60.dat')
fd = fopen('newdirs.dat','w');
% NB: this changes with the number of directions
for (i=0:64) 
    F = transform((i*4+1):((i*4+1)+2),1:3); 
    R = ((F*F')^(-0.5))*F;
    %  disp(dirs(i+1,1:3));
    dir = (real(R))*dirs(i+1,1:3)';
    %  disp(dir');
    fprintf(fd,'%f %f %f\n',dir);
end
fclose(fd);
quit;
