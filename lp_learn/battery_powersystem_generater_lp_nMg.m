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
batteryout_max=3;
batteryout_min=-3;
battery_cap=40;
battery_soc_init=0.5;

pv_charge=sum(pv_out);
for i=1:nPeriods
    if demand_data(i,nMg)-pv_out(i)>=0
        net_load(i)=demand_data(i,nMg)-pv_out(i);
    else
        charge_load(i)=pv_out(i)-demand_data(i,nMg);
    end
end

battery_cap_max=1203;
battery_out=4;
levelling_level=30;
Mg=2;

%for Mg=1:1
%% 解の上下限設定
lb=-ones(nPeriods,nBattery*2);
lb=lb(:);
ub=ones(size(lb));
ub=ub(:);


%% 線形制約設定
Bin=-batteryout_max*ones(nPeriods,nBattery);
Bout=batteryout_max*ones(nPeriods,nBattery);
B_n=zeros(1,nBattery);
for i=1:nBattery
    B_n(i)=10000/(10000+i);
end
%効率導入
% for i=1:nPeriods
%     Bout(i,:)=B_n;
% end
    
Bsum=[Bout*3];
f=[Bout(:);];

%need_power=demand_data(:,Mg)-pv_out-levelling_level;
need_power=demand_data(:,Mg)-levelling_level;
%need_power=demand_data(:,Mg)-pv_out;
%need_power=net_load;
Aeq=zeros(nPeriods,nPeriods*nBattery);

for h=1:nPeriods
    for Bno=1:nBattery
        Aeq(h,(h-1)*nBattery+Bno)=1;
    end
end
for h=1:nPeriods
    for Bno=1:nBattery
        Aeq(h,(h-1)*nBattery+Bno)=B_n(Bno);
    end
end
%A=[A;4*ones(1,nPeriods*nBattery)];
%A=[-A A];
%b=[need_power;battery_cap_max;].';
beq=[need_power;].';
beq=beq(:);
%intcon=1:length(f);
intcon=[];


%% 目的関数設定
% options = optimoptions('intlinprog','Display','final');
options =[];
[x,fval1,exitflag1,output1] = intlinprog(f,intcon,[],[],Aeq,beq,lb,ub,options);


%% 解の分割
if not(isempty(x))
    %時間、蓄電池番号毎に
    outx=zeros(size(Bsum));
    for h=1:nPeriods
        for Bno=1:nBattery
            outx(h,Bno)=-x((h-1)*nBattery+Bno);
        end
    end
    sum_out=sum(outx.').';
    
    %それぞれのSOC計算
    battery_soc=zeros(size(outx));
        battery_soc(1,:)=battery_cap*battery_soc_init;
    for Bno=1:nBattery
        for h=1:nPeriods-1
           battery_soc (h+1,Bno)=battery_soc (h,Bno)+outx(h,Bno);
        end
    end

    %     after_optim_flow=demand_data(:,Mg)-(sum_out+pv_out);
    after_optim_flow=demand_data(:,Mg)+(sum_out);
    %need_capacity=-sum(sum_out);
    battary_soc_b=zeros(nPeriods,1);
    for i = 1:nPeriods-1
        battary_soc_b(i+1)=battary_soc_b(i)+sum_out(i);
    end
    [S,L] = bounds(battary_soc_b);
    need_capacity=L-S;
    
    disp('最適化前RMSE：'+string(rms(demand_data(:,Mg),levelling_level)))
    disp('最適化後RMSE：'+string(rms(after_optim_flow,levelling_level)))
    disp('必要な蓄電池容量：'+string(need_capacity)+'kWh')
    %1枚の図におさめたい,平準化レベルも
    figure_out('Processed Data_load',demand_data(:,Mg),[0.5 24.5],[0 70],'Time [hour]','demand [kWh]')
    figure_out('Processed Data_load',after_optim_flow,[0.5 24.5],[0 70],'Time [hour]','flow [kWh]')
    figure_out('Processed Data_load',sum_out,[0.5 24.5],[-70 70],'Time [hour]','battary charge[kWh]')
    % figure_out('Processed Data_load',pv_out,[0.5 24.5],[0 150],'Time [hour]','pvout [kWh]')
end
%end

