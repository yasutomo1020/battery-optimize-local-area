r=[352 161 44 429 473 495];
s=0;
f = factorial(numel(r));
result=zeros(1:numel(r));
for i=1:numel(r)
    for j=1:numel(r)
        if(i~=j)
            s=r(i)+r(j);
            if(s<500)
