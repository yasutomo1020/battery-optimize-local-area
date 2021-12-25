rmse=zeros(40,1);
for i=1:40
     rmse(i,1)=LPfunc(0.00001,0.00001,i);
end
   