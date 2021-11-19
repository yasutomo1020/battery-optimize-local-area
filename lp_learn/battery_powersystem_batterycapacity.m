%% ヘッダー
disp('---------------------------------------------------------------------------------------')
dt = datetime('now');
DateString = datestr(dt,'yyyy年mm月dd日HH時MM分ss秒FFF');
disp(DateString)


%% 定数変数定義
clear;
close all
%load('const.mat');
nMg=3;
nPeriods=24;
nBattery=100;
Battery_maxout=3;
battery_capacity=40;
%nPV=100;
load('const.mat');
% net_load=zeros(nPeriods,1);
% charge_load=zeros(nPeriods,1);
%
% pv_charge=sum(pv_out);
% for i=1:nPeriods
%     if demand_data(i,nMg)-pv_out(i)>=0
%         net_load(i)=demand_data(i,nMg)-pv_out(i);
%     else
%         charge_load(i)=pv_out(i)-demand_data(i,nMg);
%     end
% end

levelling_level=25;
Mg=1;
need_power=demand_data(:,1)-mean(demand_data(:,1));

%for Mg=1:1
%% 解の上下限設定
battery_out=3;
lb=-ones(nBattery,nPeriods)*battery_out;
lb=lb(:);
ub=ones(size(lb))*battery_out;
ub=ub(:);
% lb=[];
% ub=[];

%% 制約
f=ones(nPeriods,nBattery);
f=f(:);

Aeq_1=eye(24);
beq=need_power;

Aeq=Aeq_1;
for i=1:nBattery-1
    Aeq=cat(2,Aeq,Aeq_1);
end

A_1=tril(ones(nPeriods));
zero_1=zeros(nPeriods);

for i=1:nBattery
    if i==1
        A_j=A_1;
    else
        A_j=zero_1;
    end
    for j=2:nBattery
        if i==j
            A_j=cat(2,A_j,A_1);
        else
            A_j=cat(2,A_j,zero_1);
        end
    end
    if i==1
        A=A_j;
    else
        A=cat(1,A,A_j);
    end
end

A=[A;-A;];
b=ones(nPeriods*nBattery,1)*battery_capacity/2;
b=[b;b;];
intcon=[];
% A=[]
% b=[]


%% 最適
options =[];
% options = optimoptions('intlinprog','CutMaxIterations',25);
% options = optimoptions('intlinprog','CutGeneration','advanced');
% options = optimoptions('intlinprog','IntegerPreprocess','advanced');
% options = optimoptions('intlinprog','RootLPAlgorithm','primal-simplex');
% options = optimoptions('intlinprog','HeuristicsMaxNodes',100);
[x,fval,eflag,output] = intlinprog(f,intcon,A,b,Aeq,beq,lb,ub,options);


%% 解の分解整理
outx=zeros(nPeriods,nBattery);
for n=1:nBattery
    for h=1:nPeriods
        outx(h,n)=x(h+(n-1)*nPeriods);
    end
end

capx=zeros(nPeriods+1,nBattery);
capx(1,:)=battery_capacity/2;
for n=1:nBattery
    for h=1:nPeriods
        capx(h+1,n)=capx(h,n)-outx(h,n);
    end
end

output=sum(outx.');
output=output.';
