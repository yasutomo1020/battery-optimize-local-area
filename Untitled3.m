flag=zeros(1,1001);
for i=1:1000
    flag(1,i)=bpsa(0.4,0.001*i);
end