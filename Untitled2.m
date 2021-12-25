%% 蓄電池EV重み係数変更による電力融通量の変化　
init=0.00001;
e=0.9;
i_max=100;
dist=zeros(i_max,2);
b_w=init;
d_w=init;
for i=1:i_max
    i
    dist(i,1)=b_w;
    dist(i,2)=LPfunc(b_w,d_w);
    b_w=b_w/e;
    d_w=d_w*e;
end

fprintf('終了');