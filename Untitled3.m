rmse=zeros(100,1);
tic
for i=1:100
     rmse(i,1)=LPfunc(0.000,0.0000,1,i/100);
     disp(i);
end
toc
   