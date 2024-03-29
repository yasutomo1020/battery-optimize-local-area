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
ev_rate=0.5;
pv_rate=1;
evload_rate=1;
Area_ev=[2 10 10]*ev_rate;%EV台数
Area_demand=[500 35 35];%需要家数
battery_capacity=12;
battery_capacity_area=battery_capacity*(Area_ev.*Area_demand);%バッテリー容量
demand_data=demand_data.*Area_demand;%需要合計
pv_out_6h=circshift(pv_out_1kw,19);%今庄エリアで片面受光型傾斜角30°PV容量1kwのカーブ、６時からに変更
pv_capacity=4.1;%基準PV容量
pv_out=pv_capacity*[1 2.1301 2.1988].*pv_out_6h*pv_rate;%住宅を１として、屋根面積比で計算
netload=demand_data+ev_out*evload_rate*Area_ev.*Area_demand-pv_out.*Area_demand;%ネットロード計算
need_power=netload;
levelling_level=mean(netload);%目標のレベル
%levelling_level=mean(netload);
initial_soc=0.5;%初期SOC
pws_capacity=10000;%配電線容量(10MW)
b_w=0.00001;%蓄電池排他制約の重み係数
d_w=0.00001;%エリア間電力融通(配電損失)排他制約重み係数
A_w=1;%目的関数設定制約条件の重み係数
initial_capacity=battery_capacity_area*initial_soc;%初期容量
before_flow=demand_data+ev_out*Area_ev.*Area_demand;%EV負荷含む潮流

%% 解の上下限設定
battery_out=3*(Area_ev.*Area_demand);
lb=[zeros(nPeriods,6) zeros(nPeriods,6)];
lb=[lb(:);-Inf*ones(nPeriods,1);];
ub=[ones(nPeriods,6).*[battery_out battery_out] pws_capacity*ones(nPeriods,6)];
ub=[ub(:);Inf*ones(nPeriods,1);];
% lb=[-ones(nPeriods,3).*battery_out zeros(nPeriods,3) -ones(nPeriods,3).*pws_capacity zeros(nPeriods,3)];
% lb=[lb(:);-Inf*ones(nPeriods,1);];
% ub=[ones(nPeriods,3).*battery_out zeros(nPeriods,3) ones(nPeriods,3).*pws_capacity zeros(nPeriods,3)];
% ub=[ub(:);Inf*ones(nPeriods,1);];
% lb=[];
% ub=[];

%% 目的関数
f=zeros(nPeriods,nArea*2);%電力量変数設定、排他条件設定
f=[f;zeros(nPeriods,factorial(nArea));].';
f=[f(:);1*ones(nPeriods,1);];%変数z（目的関数）
H=zeros(size(f,1));
for i=nPeriods*nArea*2*2:nPeriods*nArea*2*2+nPeriods
    H(i,i)=0;
end

for i=1:nPeriods*nArea*2*2
    if i<=nPeriods*nArea*2
        H(i,i)=b_w;
    else
        H(i,i)=d_w;
    end
end
%H=[];
% f=[f f f f];

%% 不等式制約
one_tril=tril(ones(nPeriods));%階段行列
one_eye=eye(nPeriods);%単位行列
zero_1=zeros(nPeriods);%零行列
A1_eye=cat(2,one_eye,zero_1,zero_1,-one_eye,zero_1,zero_1,-one_eye,zero_1,one_eye,one_eye,zero_1,-one_eye,zero_1);
A2_eye=cat(2,zero_1,one_eye,zero_1,zero_1,-one_eye,zero_1,one_eye,-one_eye,zero_1,-one_eye,one_eye,zero_1,zero_1);
A3_eye=cat(2,zero_1,zero_1,one_eye,zero_1,zero_1,-one_eye,zero_1,one_eye,-one_eye,zero_1,-one_eye,one_eye,zero_1);
A1_tril=cat(2,one_tril,zero_1,zero_1,-one_tril,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1);
A2_tril=cat(2,zero_1,one_tril,zero_1,zero_1,-one_tril,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1);
A3_tril=cat(2,zero_1,zero_1,one_tril,zero_1,zero_1,-one_tril,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1);
%蓄電池容量制約ver.2（SOCまだ）
% A1_tril=cat(2,one_tril,zero_1,zero_1,-one_tril,zero_1,zero_1,-one_tril,zero_1,one_tril,one_tril,zero_1,-one_tril,zero_1);
% A2_tril=cat(2,zero_1,one_tril,zero_1,zero_1,-one_tril,zero_1,one_tril,-one_tril,zero_1,-one_tril,one_tril,zero_1,zero_1);
% A3_tril=cat(2,zero_1,zero_1,one_tril,zero_1,zero_1,-one_tril,zero_1,one_tril,-one_tril,zero_1,-one_tril,one_tril,zero_1);
%蓄電池EV容量制約
A_cap=cat(1,A1_tril,A2_tril,A3_tril);
A_cap=[A_cap;-A_cap;];
b_l=ones(nPeriods,3).*(initial_capacity);%蓄電池容量下限
b_h=ones(nPeriods,3).*(battery_capacity_area-initial_capacity);%蓄電池容量上限
b_cap=[b_l(:);b_h(:);];
%需給バランス制約
A_load=cat(1,A1_eye,A2_eye,A3_eye);
b_load=need_power(:);%必要電力量（ネットロード）
%目的関数設定制約
A_f_1=[A_w*[one_eye one_eye one_eye -one_eye -one_eye -one_eye zero_1 zero_1 zero_1 zero_1 zero_1 zero_1] -one_eye];
A_f_2=[A_w*[-one_eye -one_eye -one_eye one_eye one_eye one_eye zero_1 zero_1 zero_1 zero_1 zero_1 zero_1] -one_eye];
b_f_1=A_w*sum((netload-levelling_level).').';
b_f_2=A_w*sum((-netload+levelling_level).').';
A_f=[A_f_1;A_f_2;];
b_f=[b_f_1;b_f_2;];
%制約条件まとめ
sw_c=1;
sw_l=1;
A=[sw_c*A_cap;sw_l*A_load;A_f];
b=[sw_c*b_cap;sw_l*b_load;b_f];
%A=[];b=[];

%% 等式制約
% Aeq1_tril=cat(2,one_tril,zero_1,zero_1,-one_tril,zero_1,zero_1,one_tril,zero_1,zero_1,zero_1,zero_1,one_tril,zero_1);
% Aeq2_tril=cat(2,zero_1,one_tril,zero_1,zero_1,-one_tril,zero_1,zero_1,one_tril,zero_1,one_tril,zero_1,zero_1,zero_1);
% Aeq3_tril=cat(2,zero_1,zero_1,one_tril,zero_1,zero_1,-one_tril,zero_1,zero_1,one_tril,zero_1,one_tril,zero_1,zero_1);
Aeq1_tril=cat(2,one_tril,zero_1,zero_1,-one_tril,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1);
Aeq2_tril=cat(2,zero_1,one_tril,zero_1,zero_1,-one_tril,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1);
Aeq3_tril=cat(2,zero_1,zero_1,one_tril,zero_1,zero_1,-one_tril,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1);
%初期充電量制約（最初と最後を比較して蓄電池残量変化なし）
Aeq=[Aeq1_tril(24,:);Aeq2_tril(24,:);Aeq3_tril(24,:);];
beq=[0;0;0;];
%Aeq=[];beq=[];

%% 整数制約
intcon=[];

%% 最適化
options =[];
% options = optimoptions('intlinprog','CutMaxIterations',25);
% options = optimoptions('intlinprog','CutGeneration','advanced');
% options = optimoptions('intlinprog','IntegerPreprocess','advanced');
%options = optimoptions('intlinprog','RootLPAlgorithm','primal-simplex');
%options = optimoptions('intlinprog','RootLPAlgorithm','dual-simplex');
%  options = optimoptions('intlinprog','HeuristicsMaxNodes',100);
%  options = optimoptions('intlinprog','Heuristics','rss');
%options = optimoptions('linprog','Algorithm','interior-point');
tic
[x,fval,eflag,out] = quadprog(H,f,A,b,Aeq,beq,lb,ub,options);
%[x,fval,eflag,out] = linprog(f,A,b,Aeq,beq,lb,ub,options);
toc
% [x,fval,eflag,out] = lsqlin(f,1,A,b,Aeq,beq,lb,ub,options);

%% 解の分解整理
if isempty(fval)==0
    outx=zeros(nPeriods,(numel(f)-nPeriods)/nPeriods);
    for n=1:(numel(f)-nPeriods)/nPeriods
        for h=1:nPeriods
            outx(h,n)=x(h+(n-1)*nPeriods);
        end
    end
    outx=round(outx,2);
    % afterflow=zeros(nPeriods,3);
    % for n=1:3
    %     for h=1:nPeriods
    %         afterflow(h,n)=outx(h,n)-outx(h,n+3)+outx(h,n+6)-outx(h,n+9);
    %     end
    % end
    % outx_all=zeros(nPeriods,nArea*2);
    % for n=1:nArea*2
    %     for h=1:nPeriods
    %         outx_all(h,n)=x(h+(n-1)*nPeriods);
    %     end
    % end
    
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
    out_b(:,1)=outx(:,1)-outx(:,4)-outx(:,7)+outx(:,9)+outx(:,10)-outx(:,12);
    out_b(:,2)=outx(:,2)-outx(:,5)+outx(:,7)-outx(:,8)-outx(:,10)+outx(:,11);
    out_b(:,3)=outx(:,3)-outx(:,6)+outx(:,8)-outx(:,9)-outx(:,11)+outx(:,12);
    after_flow=netload-out_b;
    out_symbol=zeros(nPeriods,6);
    for i=1:3
        out_symbol(:,i)=outx(:,i)-outx(:,i+3);
        out_symbol(:,i+3)=outx(:,i+6)-outx(:,i+3);
    end
    result_flow=[ sum(before_flow.').'  sum(after_flow.').'];
    
    fprintf('MAE\n最適化前：%g\n最適化後：%g\n',string(round(mae(before_flow),4)),string(round(mae(after_flow),4)));
    fprintf('RMSE\n最適化前：%g\n最適化後：%g\n',string(round(rms(sum(before_flow.').',sum(levelling_level)),4)),string(round(rms(sum(after_flow.').',sum(levelling_level)),4)));
    fprintf('・蓄電池充放電量：%g\n',sum(sum(outx(:,1:6)).'));
    fprintf('・電力融通量：%g\n',sum(sum(outx(:,7:12)).'));
    %% figure出力
   % filename="QP,ev0.5,pv1";
   filename="QP,ev"+ev_rate+",pv"+pv_rate;
    save=1;%1ならば保存する
    figure_out('plot',filename+'SOC推移プロット',socx,[1 25],[0 1],'時刻','State Of Charge',[1.25 0.55 0.25 0.4],["住宅エリア";"商業エリア";"工業エリア"],{'#7030A0','#00B050','#A5A5A5'},'%,.1f',save)
    %figure_out('bar','最適化前flow',before_flow,[0 25],[0 3000],'Time [hour]','Power Flow[kWh]',[1.25 0.3 0.25 0.3],["Residential";"Commercial";"Industrial"],[],save)
    %figure_out('bar','最適化後flow',after_flow,[0 25],[0 3000],'Time [hour]','Power Flow[kWh]',[1.0 0.3 0.25 0.3],["Residential";"Commercial";"Industrial"],[],save)
    figure_out('plot',filename+'最適化結果',result_flow,[0 25],[0 3300],'時刻','配電用変電所からの潮流[kW]',[1.0 0.55 0.25 0.4],["最適化前","最適化後"],{'#C00000','#0000ff'},'%,.0f',save)
    %figure_out('heatmap',filename+'充放電状態',outx,[],[],[],'Time [hour]',[1.0 0.0 0.5 0.55],[],[],save)
    figure_out('plot_big',filename+'充放電状態プロット',[outx(:,1:3) -outx(:,4:6)],[0 25],[-1090 1090],'時刻','電力量[kW]',[1.5 0.5 0.5 0.45],["蓄電池放電量（住宅）","蓄電池放電量（商業）","蓄電池放電量（工業）","蓄電池充電量（住宅）","蓄電池充電量（商業）","蓄電池充電量（工業）"],[],'%,.0f',save)
    figure_out('plot_big',filename+'電力融通状態プロット',[outx(:,7:9) -outx(:,10:12)],[0 25],[-1090 1090],'時刻','電力量[kW]',[1.5 0 0.5 0.45],["エリア間電力融通（住宅→商業）","エリア間電力融通（商業→工業）","エリア間電力融通（工業→住宅）","エリア間電力融通（商業→住宅）","エリア間電力融通（工業→商業）","エリア間電力融通（住宅→工業）"],[],'%,.1f',save)
end