%% ヘッダー
disp('---------------------------------------------------------------------------------------')
dt = datetime('now');
DateString = datestr(dt,'yyyy年mm月dd日HH時MM分ss秒FFF');
disp(DateString)
clear;
close all;
load('const.mat');

%% 定数変数定義
nPeriods=24;%期間数
nArea=6;%エリア数
Area_ev=[2 10 10];%EV台数
Area_demand=[500 35 35];%需要家数
battery_capacity=40*(Area_ev.*Area_demand);%バッテリー容量
demand_data=demand_data.*Area_demand;
pv_out=pv_out;%常に晴ということは無いので、半分に←無し
% pv_out=1*ones(24,1);%常に1
%pv_out=[pv_out(1:9);1*ones(15,1)];%10番目から常に1
pv_out=[pv_out 10*pv_out 10*pv_out];
netload=demand_data+ev_out*Area_ev.*Area_demand-pv_out.*Area_demand;%ネットロード計算
levelling_level=0;
%need_power=netload-mean(demand_data);%「要検討」
%need_power=netload-mean(netload);
need_power=netload-levelling_level;
%need_power=-pv_out.*Area_demand;
pws_capacity=Inf;
initial_capacity=battery_capacity*0.8;

%% 解の上下限設定
battery_out=3*(Area_ev.*Area_demand);
lb=[zeros(nPeriods,6) zeros(nPeriods,6)];
lb=[lb(:);-Inf;];
ub=[ones(nPeriods,6).*[battery_out battery_out] pws_capacity*ones(nPeriods,6)];
ub=[ub(:);Inf;];
% lb=[];
% ub=[];

%% 目的関数
eff=0.99;
f=zeros(nPeriods,3);
f=[f f f*eff f*eff];
f=[f(:);-1;];
% f=[f f f f];

%% 不等式制約
A_tril=tril(ones(nPeriods));
Aeq_eye=eye(nPeriods);
zero_1=zeros(nPeriods);
zero_z=zeros(nPeriods,1);
A1_tril=cat(2,A_tril,zero_1,zero_1,-A_tril,zero_1,zero_1,A_tril,zero_1,zero_1,zero_1,zero_1,A_tril,zero_z);
A2_tril=cat(2,zero_1,A_tril,zero_1,zero_1,-A_tril,zero_1,zero_1,A_tril,zero_1,A_tril,zero_1,zero_1,zero_z);
A3_tril=cat(2,zero_1,zero_1,A_tril,zero_1,zero_1,-A_tril,zero_1,zero_1,A_tril,zero_1,A_tril,zero_1,zero_z);
A1_eye=cat(2,Aeq_eye,zero_1,zero_1,-Aeq_eye,zero_1,zero_1,-Aeq_eye,zero_1,Aeq_eye,Aeq_eye,zero_1,-Aeq_eye,zero_z);
A2_eye=cat(2,zero_1,Aeq_eye,zero_1,zero_1,-Aeq_eye,zero_1,Aeq_eye,-Aeq_eye,zero_1,-Aeq_eye,Aeq_eye,zero_1,zero_z);
A3_eye=cat(2,zero_1,zero_1,Aeq_eye,zero_1,zero_1,-Aeq_eye,zero_1,Aeq_eye,-Aeq_eye,zero_1,-Aeq_eye,Aeq_eye,zero_z);

A=cat(1,A1_tril,A2_tril,A3_tril);
A=[A;-A;];
b_l=ones(nPeriods,3).*(initial_capacity);
b_h=ones(nPeriods,3).*(battery_capacity-initial_capacity);
% b_l=ones(nPeriods,3).*5000;
% b_h=ones(nPeriods,3).*1000;
b=[b_l(:);b_h(:);];
A=[A;cat(1,A1_eye,A2_eye,A3_eye);];
b=[b;need_power(:);];
% A=[];b=[];

%% 等式制約
% Aeq=[A(24,:);A(48,:);A(72,:);cat(1,A1_eye,A2_eye,A3_eye);];
% beq=[0;0;0;need_power(:);];

% zero_6=cat(2,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1);
% Aeq=cat(1,A1_eye,A2_eye,A3_eye);
% Aeq_k1=cat(2,zero_1,Aeq_eye,Aeq_eye,-Aeq_eye,zero_1,zero_1);
% Aeq_k2=cat(2,Aeq_eye,zero_1,Aeq_eye,zero_1,-Aeq_eye,zero_1);
% Aeq_k3=cat(2,Aeq_eye,Aeq_eye,zero_1,zero_1,zero_1,-Aeq_eye);
% Aeq_k4=cat(2,Aeq_eye,zero_1,zero_1,zero_1,-Aeq_eye,-Aeq_eye);
% Aeq_k5=cat(2,zero_1,Aeq_eye,zero_1,-Aeq_eye,zero_1,-Aeq_eye);
% Aeq_k6=cat(2,zero_1,zero_1,Aeq_eye,-Aeq_eye,-Aeq_eye,zero_1);
% Aeq_k1=[zero_6 Aeq_k1]; Aeq_k2=[zero_6 Aeq_k2]; Aeq_k3=[zero_6 Aeq_k3];
% Aeq_k4=[zero_6 Aeq_k4]; Aeq_k5=[zero_6 Aeq_k5]; Aeq_k6=[zero_6 Aeq_k6];
% beq=need_power(:);
%beq=[beq;zeros(144,1)];
% Aeq=[A(24,:);A(48,:);A(72,:);]; beq=[0;0;0;]; Aeq=[];beq=[];
% A=[A;Aeq;-Aeq;]; b=[b;beq+0.1;-(beq-0.1);]; A=[A;Aeq;]; b=[b;beq;];
% Aeq=[];beq=[]; Aeq=[Aeq;A(24,:);A(48,:);A(72,:);]; beq=[beq;0;0;0;];
% Aeq=[];beq=[];
% Aeq=[Aeq;ones(1,288) -1;];
Aeq=[ones(1,nPeriods) ones(1,nPeriods) ones(1,nPeriods) -ones(1,nPeriods) -ones(1,nPeriods) -ones(1,nPeriods)];
% zeroq=[zeros(1,nPeriods) zeros(1,nPeriods) zeros(1,nPeriods) zeros(1,nPeriods) zeros(1,nPeriods) zeros(1,nPeriods)];
zeroq=0.01*[-ones(1,nPeriods) -ones(1,nPeriods) -ones(1,nPeriods) -ones(1,nPeriods) -ones(1,nPeriods) -ones(1,nPeriods)];
Aeq=[Aeq zeroq -1;];
beq=0;
Aeq=[Aeq;A(24,:);A(48,:);A(72,:);];
beq=[beq;0;0;0;];
%% 整数制約
intcon=[];

%% 最適化
options =[];
% options = optimoptions('intlinprog','CutMaxIterations',25);
% options = optimoptions('intlinprog','CutGeneration','advanced');
% options = optimoptions('intlinprog','IntegerPreprocess','advanced');
% options = optimoptions('intlinprog','RootLPAlgorithm','primal-simplex');
% options = optimoptions('intlinprog','HeuristicsMaxNodes',100);
tic
[x,fval,eflag,out] = intlinprog(f,intcon,A,b,Aeq,beq,lb,ub,options);
toc

%% 解の分解整理
outx=zeros(nPeriods,(numel(f)-1)/nPeriods);
for n=1:(numel(f)-1)/nPeriods
    for h=1:nPeriods
        outx(h,n)=x(h+(n-1)*nPeriods);
    end
end
afterflow=zeros(nPeriods,3);
for n=1:3
    for h=1:nPeriods
        afterflow(h,n)=outx(h,n)-outx(h,n+3)+outx(h,n+6)-outx(h,n+9);
    end
end
% outx_all=zeros(nPeriods,nArea*2);
% for n=1:nArea*2
%     for h=1:nPeriods
%         outx_all(h,n)=x(h+(n-1)*nPeriods);
%     end
% end

%% 容量（SOC）計算
capx=zeros(nPeriods+1,3);
capx(1,:)=initial_capacity;
for h=1:nPeriods
    capx(h+1,1)=capx(h,1)-outx(h,1)+outx(h,4)-outx(h,7)-outx(h,12);
    capx(h+1,2)=capx(h,2)-outx(h,2)+outx(h,5)-outx(h,8)-outx(h,10);
    capx(h+1,3)=capx(h,3)-outx(h,3)+outx(h,6)-outx(h,9)-outx(h,11);
    %     capx(h+1,1)=capx(h,1)-(outx(h,1)-outx(h,4)-outx(h,7)+outx(h,9)+outx(h,10)-outx(h,12));
    %     capx(h+1,2)=capx(h,2)-(outx(h,2)-outx(h,5)+outx(h,7)-outx(h,8)-outx(h,10)+outx(h,11));
    %     capx(h+1,3)=capx(h,3)-(outx(h,3)-outx(h,6)+outx(h,8)-outx(h,9)-outx(h,11)+outx(h,12));
end
capx=round(capx,4);
% capx=capx+battery_capacity*battery_safelimit/2;

%% 合計
out_b=zeros(nPeriods,3);
out_b(:,1)=outx(:,1)-outx(:,4)-outx(:,7)+outx(:,9)+outx(:,10)-outx(:,12);
out_b(:,2)=outx(:,2)-outx(:,5)+outx(:,7)-outx(:,8)-outx(:,10)+outx(:,11);
out_b(:,3)=outx(:,3)-outx(:,6)+outx(:,8)-outx(:,9)-outx(:,11)+outx(:,12);
after_flow=netload-out_b;
out_symbol=zeros(nPeriods,6);
for i=1:3
    out_symbol(:,i)=outx(:,i)-outx(:,i+3);
    out_symbol(:,i+3)=outx(:,i+6)-outx(:,i+3);
end


%% figure出力
figure_out_bar('ネットロード',netload,[0 25],[0 3000],'Time [hour]','netload[kWh]',[1.25 0.1 0.25 0.3])
figure_out_plot('容量推移',capx,[1 25],[0 battery_capacity],'Time [hour]','capacity [kWh]',[1.0 0.1 0.25 0.3])
figure_out_bar('最適化前',demand_data+ev_out*Area_ev.*Area_demand,[0 25],[0 3000],'Time [hour]','beforeflow [kWh]',[1.25 0.4 0.25 0.3])
figure_out_bar('最適化後',after_flow,[0 25],[0 3000],'Time [hour]','afterflow [kWh]',[1.0 0.4 0.25 0.3])
%figure_out_bar('result',demand_data,[0 25],[0 3000],'Time [hour]','load(without ev) [kWh]',[1.7 0.1 0.2 0.5])
%figure_out_bar('result',ev_out,[0 25],[0 1],'Time [hour]','evout [kWh]')
%figure_out_bar('Processed Data_load',pv_out,[0 25],[0 1.5],'Time
%[hour]','pvout [kWh]')
%figure_out_plot('result',netload,[0 24],[-3 3],'Time [hour]','netload [kWh]')

