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
%nPV=100;
load('const.mat');
net_load=zeros(nPeriods,1);
charge_load=zeros(nPeriods,1);

pv_charge=sum(pv_out);
for i=1:nPeriods
    if demand_data(i,nMg)-pv_out(i)>=0
        net_load(i)=demand_data(i,nMg)-pv_out(i);
    else
        charge_load(i)=pv_out(i)-demand_data(i,nMg);
    end
end

battery_cap_max=1203;
battery_out=1.0000001;
levelling_level=25;
Mg=1;

%for Mg=1:1
%% 解の上下限設定
lb=-ones(nPeriods,nBattery);
lb=lb(:);
ub=ones(size(lb));
ub=ub(:);


%% 線形制約設定
Bout=battery_out*ones(nPeriods,nBattery);
f=Bout(:);

%need_power=demand_data(:,Mg)-pv_out-levelling_level;

%need_power=demand_data(:,Mg)-pv_out;
%need_power=net_load;
A=zeros(nPeriods*nMg,length(f));
demand=zeros(nPeriods,nMg);
for Mg=1:nMg
    for h=1:nPeriods
        if Mg==1
            for Bno=1:40
                A(h+nPeriods*(Mg-1),(h-1)*nBattery+Bno)=battery_out;
                demand(h,Mg)=demand(h,Mg)+demand_1(h,Mg);
            end
        elseif Mg==2
            for Bno=41:70
                A(h+nPeriods*(Mg-1),(h-1)*nBattery+Bno)=battery_out;
                demand(h,Mg)=demand(h,Mg)+demand_1(h,Mg);
            end
        elseif Mg==3
            for Bno=71:100
                A(h+nPeriods*(Mg-1),(h-1)*nBattery+Bno)=battery_out;
                demand(h,Mg)=demand(h,Mg)+demand_1(h,Mg);
            end
        end
    end
end
%
need_power=demand-levelling_level/nMg;
%need_power=demand
%A=[A;1*ones(1,nPeriods*nBattery)];
%A=[A;];
% b=[need_power;battery_cap_max;].';
b=[need_power(:);];
%b=b(:);
intcon=1:length(f);
%intcon=[];

%% 目的関数設定
%options = optimoptions('intlinprog','Display','final');
options =[];
[x,fval,eflag,output] = intlinprog(-f,intcon,A,b,[],[],lb,ub,options);

%% 解の分割
outx=zeros(nPeriods*nMg,nBattery);
if not(isempty(x))
    for Mg=1:nMg
        for h=1:nPeriods
            for Bno=1:40
                outx(h+nPeriods*0,Bno)=battery_out*x((h-1)*nBattery+Bno);
            end
            for Bno=41:70
                outx(h+nPeriods*1,Bno)=battery_out*x((h-1)*nBattery+Bno);
            end
            for Bno=71:100
                outx(h+nPeriods*2,Bno)=battery_out*x((h-1)*nBattery+Bno);
            end
        end
    end
    sum_out=sum(outx.').';
    sum_out_3=zeros(nPeriods,nMg);
    for i=1:nPeriods
        sum_out_3(i,1)=sum_out(i+nPeriods*0,1);
        sum_out_3(i,2)=sum_out(i+nPeriods*1,1);
        sum_out_3(i,3)=sum_out(i+nPeriods*2,1);
    end
    %     for i=1:nPeriods
    %         sum_out_24(nPeriods,1)=sum_out(nPeriods,1)+sum_out(nPeriods*2,1)+sum_out(nPeriods*3,1)
    %     end
    sum_demand=sum(demand.').';
    %     after_optim_flow=demand_data(:,Mg)-(sum_out+pv_out);
    after_optim_flow=demand-(sum_out_3);
    sum_after_optim_flow=sum(after_optim_flow.').';
    %need_capacity=-sum(sum_out);
    battary_soc=zeros(nPeriods,1);
    for i = 1:nPeriods-1
        battary_soc(i+1)=battary_soc(i)+sum_out(i);
    end
    [S,L] = bounds(battary_soc);
    need_capacity=L-S;
    
    disp('最適化前RMSE：'+string(rms(sum_demand,levelling_level)))
    disp('最適化後RMSE：'+string(rms(sum_after_optim_flow,levelling_level)))
    disp('必要な蓄電池容量：'+string(need_capacity)+'kWh')
    %1枚の図におさめたい,平準化レベルも
    figure_out('Processed Data_load',demand,[0.5 24.5],[0 70],'Time [hour]','demand [kWh]')
    figure_out('Processed Data_load',after_optim_flow,[0.5 24.5],[0 70],'Time [hour]','flow [kWh]')
    figure_out('Processed Data_load',sum_out_3,[0.5 24.5],[-30 30],'Time [hour]','battary charge[kWh]')
    %figure_out('Processed Data_load',pv_out,[0.5 24.5],[0 250],'Time [hour]','pvout [kWh]')
end
%end

