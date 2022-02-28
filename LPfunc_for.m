max=40
distsum=zeros(max,1);
tic
for i=1:max
     distsum(i,1)=LPfunc(0.00001,0.00001,i);
     disp(i);
end
toc
   