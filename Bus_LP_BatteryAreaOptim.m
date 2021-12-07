%% ヘッダー
disp('---------------------------------------------------------------------------------------')
dt = datetime('now');

DateString = datestr(dt,'yyyy年mm月dd日HH時MM分ss秒FFF');
disp(DateString)
%clear;
close all;
load('const.mat');

%% 定数変数定義、検討条件
nPeriods=24;%期間数
nArea=3;%エリア数
ev_rate=0.5;%EV導入率
pv_rate=0.85;%PV導入率
evload_rate=1;%EV負荷率
Area_ev=[2 10 10]*ev_rate;%エリア毎のEV台数
Area_demand_num=[500 35 35];%需要家数
battery_capacity=12;%一台当たりの蓄電池容量
battery_out_1=3;%一台当たりの最大蓄電池出力
battery_capacity_area=battery_capacity*(Area_ev.*Area_demand_num);%バッテリー容量の合計
demand_data_sum=demand_data.*Area_demand_num;%需要合計
pv_out=circshift(pv_225_su_max,19)/225;%PV設備容量1kwのカーブ
pv_capacity=6;%基準PV設備容量
pv_out=pv_capacity*[1 2.1301 2.1988].*pv_out*pv_rate;%住宅を１として、屋根面積比で計算
netload=demand_data_sum+ev_out*evload_rate*Area_ev.*Area_demand_num-pv_out.*Area_demand_num;%ネットロード計算
need_power=netload;%ネットロードを目標値にセット
levelling_level=mean(netload);%平準化レベル
%levelling_level=400;
initial_soc=0.5;%初期SOC
pws_capacity=200;%配電線容量
b_w=0.00001;%蓄電池排他制約の重み係数
d_w=0.001;%エリア間電力融通(配電損失)排他制約重み係数
A_w=1;%目的関数設定制約条件の重み係数
bus_out=250;%バスの充放電出力
bus_cap=600;%バスの容量
initial_capacity=battery_capacity_area*initial_soc;%初期容量
before_flow=demand_data_sum+ev_out*Area_ev.*Area_demand_num;%EV負荷含む潮流（最適化無しの潮流を計算）
bus_route_1=[1 1 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0;].';
bus_route_2=[0 0 0 1 1 0 0 0 0 1 1 0 0 0 0 1 1 0 0 0 0 0 0 0;].';
bus_route_3=[0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;].';
bus_route=[bus_route_1;bus_route_2;bus_route_3;];
%% 解の上下限設定
battery_out=battery_out_1*(Area_ev.*Area_demand_num);%最大蓄電池出力合計
lb=[zeros(nPeriods,6) zeros(nPeriods,6)];%蓄電池入出力と電力融通量の下限
lb=[lb(:);-Inf*ones(nPeriods,1);-Inf*ones(nPeriods*nArea,1)];%z変数とEVバス変数の下限
ub=[ones(nPeriods,6).*[battery_out battery_out] pws_capacity*ones(nPeriods,6)];%蓄電池入出力と電力融通量の上限
ub=[ub(:);Inf*ones(nPeriods,1);Inf*ones(nPeriods*nArea,1)];%z変数とEVバス変数の上限
% lb=[];
% ub=[];

%% 目的関数
f=b_w*ones(nPeriods,nArea*2);%蓄電池入出力変数設定、排他制約の係数設定
f=[f;d_w*ones(nPeriods,factorial(nArea));].';%エリア間電力融通変数設定、排他制約の係数設定
f=[f(:);ones(nPeriods,1)];%変数z設定
f=[f;bus_route(:)];%EVバス変数設定

%% 不等式制約
one_tril=tril(ones(nPeriods));%下三角行列作成
one_eye=eye(nPeriods);%単位行列作成
zero_1=zeros(nPeriods);%零行列作成
%制約条件用の行列作成
A1_eye=cat(2,one_eye,zero_1,zero_1,-one_eye,zero_1,zero_1,-one_eye,zero_1,one_eye,one_eye,zero_1,-one_eye,zero_1,one_eye,zero_1,zero_1);
A2_eye=cat(2,zero_1,one_eye,zero_1,zero_1,-one_eye,zero_1,one_eye,-one_eye,zero_1,-one_eye,one_eye,zero_1,zero_1,zero_1,one_eye,zero_1);
A3_eye=cat(2,zero_1,zero_1,one_eye,zero_1,zero_1,-one_eye,zero_1,one_eye,-one_eye,zero_1,-one_eye,one_eye,zero_1,zero_1,zero_1,one_eye);
A1_tril=cat(2,one_tril,zero_1,zero_1,-one_tril,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1);
A2_tril=cat(2,zero_1,one_tril,zero_1,zero_1,-one_tril,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1);
A3_tril=cat(2,zero_1,zero_1,one_tril,zero_1,zero_1,-one_tril,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1);
A_bus_tril=bus_out*cat(2,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,one_tril,one_tril,one_tril);
%容量制約設定
A_cap=cat(1,A1_tril,A2_tril,A3_tril,A_bus_tril);
A_cap=[A_cap;-A_cap;];
b_l=ones(nPeriods,3).*(initial_capacity);%蓄電池容量下限
b_h=ones(nPeriods,3).*(battery_capacity_area-initial_capacity);%蓄電池容量上限
b_bus_l=ones(nPeriods,1).*bus_cap/2;%バス用蓄電池容量下限
b_bus_h=ones(nPeriods,1).*bus_cap/2;%バス用蓄電池容量上限
b_cap=[b_l(:);b_bus_l(:);b_h(:);b_bus_h(:);];
%需給バランス制約
A_load=cat(1,A1_eye,A2_eye,A3_eye);
b_load=need_power(:);%必要電力量（ネットロード）
%目的関数設定制約
A_f_1=[A_w*[one_eye one_eye one_eye -one_eye -one_eye -one_eye zero_1 zero_1 zero_1 zero_1 zero_1 zero_1] -one_eye [one_eye one_eye one_eye]];
A_f_2=[A_w*[-one_eye -one_eye -one_eye one_eye one_eye one_eye zero_1 zero_1 zero_1 zero_1 zero_1 zero_1] -one_eye -[one_eye one_eye one_eye]];
b_f_1=A_w*sum((netload-levelling_level).').';
b_f_2=A_w*sum((-netload+levelling_level).').';
A_f=[A_f_1;A_f_2;];
b_f=[b_f_1;b_f_2;];
%バス存在制約(各時刻で複数存在しないように、6時～21時)
% A_bus=cat(2,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,one_eye,one_eye,one_eye,one_eye,one_eye,one_eye);
% b_bus=[ones(nPeriods-8,1);zeros(8,1)];
%制約条件まとめ
sw_c=1;%切り替え用変数
sw_l=1;%切り替え用変数
% A=[sw_c*A_cap;sw_l*A_load;A_f;A_bus];
% b=[sw_c*b_cap;sw_l*b_load;b_f;b_bus];
A=[sw_c*A_cap;sw_l*A_load;A_f;];
b=[sw_c*b_cap;sw_l*b_load;b_f;];
%A=[];b=[];

%% 等式制約
Aeq1_tril=cat(2,one_tril,zero_1,zero_1,-one_tril,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1);
Aeq2_tril=cat(2,zero_1,one_tril,zero_1,zero_1,-one_tril,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1);
Aeq3_tril=cat(2,zero_1,zero_1,one_tril,zero_1,zero_1,-one_tril,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1);
%初期充電量制約（最初と最後を比較して蓄電池残量変化なし）
Aeq=[Aeq1_tril(24,:);Aeq2_tril(24,:);Aeq3_tril(24,:);];
beq=[0;0;0;];
%Aeq=[];beq=[];

%% 整数制約
%EVバス用変数のみ0or1
%intcon=(nPeriods*nArea*4+nPeriods):(nPeriods*nArea*4+nPeriods+nPeriods*nArea*2);
intcon=[];
%% 最適化
%オプション設定
options =[];
%options = optimoptions('intlinprog','Heuristics','advanced','HeuristicsMaxNodes',10000,'RootLPAlgorithm','primal-simplex','CutMaxIterations',25,'CutGeneration','advanced','IntegerPreprocess','advanced');
tic%計算時間測定
[x,fval,eflag,out] = intlinprog(f,intcon,A,b,Aeq,beq,lb,ub,options);%最適化
%[x,fval,eflag,out] = linprog(f,A,b,Aeq,beq,lb,ub,options);
toc

%% 解の分解整理
if isempty(fval)==0
    outx=zeros(nPeriods,(numel(f))/nPeriods);
    for n=1:(numel(f))/nPeriods
        for h=1:nPeriods
            outx(h,n)=x(h+(n-1)*nPeriods);
        end
    end
    outx=round(outx,2);%丸め
    
    %% 容量（SOC）計算
    socx=zeros(nPeriods+1,3);
    socx(1,:)=initial_capacity;
    for h=1:nPeriods
        %     socx(h+1,1)=socx(h,1)-outx(h,1)+outx(h,4)-outx(h,7)-outx(h,12);
        %     socx(h+1,2)=socx(h,2)-outx(h,2)+outx(h,5)-outx(h,8)-outx(h,10);
        %     socx(h+1,3)=socx(h,3)-outx(h,3)+outx(h,6)-outx(h,9)-outx(h,11);
        socx(h+1,1)=socx(h,1)-outx(h,1)+outx(h,4);
        socx(h+1,2)=socx(h,2)-outx(h,2)+outx(h,5);
        socx(h+1,3)=socx(h,3)-outx(h,3)+outx(h,6);
    end
    socx=round(socx,4)./battery_capacity_area;
    
    %% 合計
    out_b=zeros(nPeriods,3);
    out_b(:,1)=outx(:,1)-outx(:,4)-outx(:,7)+outx(:,9)+outx(:,10)-outx(:,12)+outx(:,14);
    out_b(:,2)=outx(:,2)-outx(:,5)+outx(:,7)-outx(:,8)-outx(:,10)+outx(:,11)+outx(:,15);
    out_b(:,3)=outx(:,3)-outx(:,6)+outx(:,8)-outx(:,9)-outx(:,11)+outx(:,12)+outx(:,16);
    after_flow=netload-out_b;
    out_symbol=zeros(nPeriods,6);
    for i=1:3
        out_symbol(:,i)=outx(:,i)-outx(:,i+3);
        out_symbol(:,i+3)=outx(:,i+6)-outx(:,i+3);
    end
    result_flow=[ sum(before_flow.').'  sum(after_flow.').'];
    
    fprintf('MAE\n最適化前：%g\n最適化後：%g\n',string(round(mae(before_flow),4)),string(round(mae(after_flow),4)));
    fprintf('RMSE\n最適化前：%g\n最適化後：%g\n',string(round(rms(sum(before_flow.').',sum(levelling_level)),4)),string(round(rms(sum(after_flow.').',sum(levelling_level)),4)));
    
    %% figure出力
    save=0;%1なら保存、0なら保存しない（保存に時間がかかるため）
    figure_out('plot','SOC推移（LP）',socx,[1 25],[0 1],'Time [hour]','State Of Charge',[1.25 0.55 0.25 0.4],["住宅エリア";"商業エリア";"工業エリア"],[],save)
    %figure_out('bar','最適化前flow',before_flow,[0 25],[0 3000],'Time [hour]','Power Flow[kWh]',[1.25 0.3 0.25 0.3],["Residential";"Commercial";"Industrial"],[],save)
    %figure_out('bar','最適化後flow',after_flow,[0 25],[0 3000],'Time [hour]','Power Flow[kWh]',[1.0 0.3 0.25 0.3],["Residential";"Commercial";"Industrial"],[],save)
    figure_out('plot','最適化結果（LP）',result_flow,[0 25],[0 3000],'Time [hour]','Power Flow[kW]',[1.0 0.55 0.25 0.4],["最適化前","最適化後"],{'#FFE13C','#FFB400'},save)
    heat('充放電状態（LP）',outx,[],'Time [hour]',[1.0 0.0 0.5 0.55],{'\it P_{R}^{disch}','\it P_{C}^{disch}' ,'\it P_{I}^{disch}', '\it P_{R}^{ch}','\it P_{C}^{ch}' ,'\it P_{I}^{ch}','\it P_{RC}^{dist}','\it P_{CI}^{dist}','\it P_{IR}^{dist}','\it P_{CR}^{dist}','\it P_{IC}^{dist}','\it P_{RI}^{dist}','\it z','\it i_{R}^{busdisch}','\it i_{C}^{busdisch}','\it i_{I}^{busdisch}','\it i_{R}^{busch}','\it i_{C}^{busch}','\it i_{I}^{busch}'},save)
end