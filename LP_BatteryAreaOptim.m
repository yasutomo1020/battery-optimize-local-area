%% ヘッダー
disp('---------------------------------------------------------------------------------------')
dt = datetime('now');

DateString = datestr(dt,'yyyy年mm月dd日HH時MM分ss秒FFF');
disp(DateString)%実行時刻表示
%clear;
close all;%図を全て閉じる
load('const.mat');%定数を読み込む

%% 定数変数定義、検討条件
nPeriods=24;%期間数
nArea=3;%エリア数
ev_rate=0.5;%EV導入率
pv_rate=1;%PV導入率
evload_rate=1;%EV負荷率
Area_ev=[2 10 10]*ev_rate;%EV台数
Area_demand=[500 35 35];%需要家数
battery_capacity=12;%蓄電池容量（リーフの3割）
battery_capacity_area=battery_capacity*(Area_ev.*Area_demand);%エリアごとのバッテリー容量
demand_data=demand_data.*Area_demand;%需要合計
pv_out_6h=circshift(pv_out_1kw,19);%今庄エリアで片面受光型傾斜角30°PV容量1kwのカーブ、６時からに変更
pv_capacity=4.1;%基準PV容量（住宅）
pv_out=pv_capacity*[1 2.1301 2.1988].*pv_out_6h*pv_rate;%住宅を１として、屋根面積比でエリアごとのPV設備容量を計算
netload=demand_data+ev_out*evload_rate*Area_ev.*Area_demand-pv_out.*Area_demand;%ネットロード計算
levelling_level=mean(netload);%平準化レベルをネットロードの平均値に設定
initial_soc=0.5;%初期SOC（＝最終SOC）
pws_capacity=6000;%配電線容量(6MW)
%pws_capacity=0;
b_w=0.0001;%蓄電池排他制約の重み係数(基準：1.0*10^-5)
d_w=0.0001;%エリア間電力融通(配電損失)排他制約重み係数
% b_w=0;d_w=0;
A_w=1;%目的関数設定制約条件の重み係数
initial_capacity=battery_capacity_area*initial_soc;%初期容量
before_flow=netload;%比較グラフ作成用
%before_flow=demand_data+ev_out*Area_ev.*Area_demand;%EV負荷含む潮流

%% 解の上下限設定
battery_out=3*(Area_ev.*Area_demand);%蓄電池入出力最大値
lb=[zeros(nPeriods,6) zeros(nPeriods,6)];%蓄電池入出力下限＋エリア間電力融通下限
lb=[lb(:);-Inf*ones(nPeriods,1);];%平準化変数ｚ下限
ub=[ones(nPeriods,6).*[battery_out battery_out] pws_capacity*ones(nPeriods,6)];%蓄電池入出力上限＋エリア間電力融通上限
ub=[ub(:);Inf*ones(nPeriods,1);];%平準化変数ｚ上限

%% 目的関数設定
%変数の数は，各エリアの蓄電池放電分で72個，
%各エリアの蓄電池充電分で72個，
%エリア間の電力融通量は行き先が6通りあるので144個，
%平準化変数がそれぞれの時刻で24個，
%合計で312個あります。
f=b_w*ones(nPeriods,nArea*2);%蓄電池充放電量変数設定、重み係数設定
f=[f;d_w*ones(nPeriods,factorial(nArea));].';%エリア間の電力融通量変数設定、重み係数設定
f=[f(:);ones(nPeriods,1)];%平準化変数ｚ設定

%% 不等式制約
%行列作成
one_tril=tril(ones(nPeriods));%階段行列
one_eye=eye(nPeriods);%単位行列
zero_1=zeros(nPeriods);%零行列
%蓄電池容量制約用行列群
A1_tril=cat(2,one_tril,zero_1,zero_1,-one_tril,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1);
A2_tril=cat(2,zero_1,one_tril,zero_1,zero_1,-one_tril,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1);
A3_tril=cat(2,zero_1,zero_1,one_tril,zero_1,zero_1,-one_tril,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1,zero_1);
%需給バランス制約用行列群
A1_eye=cat(2,one_eye,zero_1,zero_1,-one_eye,zero_1,zero_1,-one_eye,zero_1,one_eye,one_eye,zero_1,-one_eye,zero_1);
A2_eye=cat(2,zero_1,one_eye,zero_1,zero_1,-one_eye,zero_1,one_eye,-one_eye,zero_1,-one_eye,one_eye,zero_1,zero_1);
A3_eye=cat(2,zero_1,zero_1,one_eye,zero_1,zero_1,-one_eye,zero_1,one_eye,-one_eye,zero_1,-one_eye,one_eye,zero_1);

%蓄電池容量制約
%1時間ごとの蓄電池入出力の総和を24時間分それぞれの時刻で求めることで，
%その時刻における蓄電池容量を算出し，それが蓄電池容量を下回らない，
%かつ上回らないような制約です。それを実現するために，階段行列を作成し，
%制約条件行列に設定して各エリアの蓄電池容量制約を作成しています。
A_cap=cat(1,A1_tril,A2_tril,A3_tril);
A_cap=[A_cap;-A_cap;];
b_l=ones(nPeriods,3).*(initial_capacity);%蓄電池容量下限
b_h=ones(nPeriods,3).*(battery_capacity_area-initial_capacity);%蓄電池容量上限
b_cap=[b_l(:);b_h(:);];

%需給バランス制約
%配電線用変電所より上位の系統に電力を送らないようにする
%（逆潮流禁止）ために，1時間ごとの配電線潮流が
%ネットロードを超えないように設定しています。
A_load=cat(1,A1_eye,A2_eye,A3_eye);
b_load=netload(:);%必要電力量（ネットロード）

%目的関数設定制約
%配電線潮流とネットロードの差の絶対値を最小化することで
%平準化を行います。
A_f_1=[A_w*[one_eye one_eye one_eye -one_eye -one_eye -one_eye zero_1 zero_1 zero_1 zero_1 zero_1 zero_1] -one_eye];
A_f_2=[A_w*[-one_eye -one_eye -one_eye one_eye one_eye one_eye zero_1 zero_1 zero_1 zero_1 zero_1 zero_1] -one_eye];
b_f_1=A_w*sum((netload-levelling_level).').';
b_f_2=A_w*sum((-netload+levelling_level).').';
A_f=[A_f_1;A_f_2;];
b_f=[b_f_1;b_f_2;];

%制約条件まとめ
sw_c=1;%1で容量制約あり，0で容量制約なし
sw_l=1;%1で需給バランス制約あり，0で需給バランス制約なし
A=[sw_c*A_cap;sw_l*A_load;A_f];
b=[sw_c*b_cap;sw_l*b_load;b_f];
%A=[];b=[];

%% 等式制約
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
options =[];%オプション
tic%計算時間測定
[x,fval,eflag,out] = intlinprog(f,intcon,A,b,Aeq,beq,lb,ub,options);%ソルバー実行
%f:目的関数，intcon:整数制約，A:不等式制約行列，b:不等式制約ベクトル，Aeq:等式制約行列，beq:等式制約ベクトル，lb:解の下限，ub:解の上限。options:ソルバーのオプション
toc

%% 解の分解整理
if isempty(fval)==0%もし解があったら
    outx=zeros(nPeriods,(numel(f)-nPeriods)/nPeriods);
    for n=1:(numel(f)-nPeriods)/nPeriods
        for h=1:nPeriods
            outx(h,n)=x(h+(n-1)*nPeriods);
        end
    end
    outx=round(outx,2);
    %1列目：住宅エリア蓄電池放電量
    %2列目：商業エリア蓄電池放電量
    %3列目：工業エリア蓄電池放電量
    %4列目：住宅エリア蓄電池充電量
    %5列目：商業エリア蓄電池充電量
    %6列目：工業エリア蓄電池充電量
    %7列目：住宅エリアから商業エリアへの電力融通量
    %8列目：商業エリアから工業エリアへの電力融通量
    %9列目：工業エリアから住宅エリアへの電力融通量
    %10列目：商業エリアから住宅エリアへの電力融通量
    %11列目：工業エリアから商業エリアへの電力融通量
    %12列目：住宅エリアから工業エリアへの電力融通量
    
    %% SOC計算
    socx=zeros(nPeriods+1,3);
    socx(1,:)=initial_capacity;
    for h=1:nPeriods
        %現在のSOC=前のSOC－充放電量
        socx(h+1,1)=socx(h,1)-outx(h,1)+outx(h,4);
        socx(h+1,2)=socx(h,2)-outx(h,2)+outx(h,5);
        socx(h+1,3)=socx(h,3)-outx(h,3)+outx(h,6);
        
    end
    socx=round(socx,4)./battery_capacity_area;
    
    %% 合計値計算
    out_b=zeros(nPeriods,3);
    out_b(:,1)=outx(:,1)-outx(:,4)+(-outx(:,7)+outx(:,9)+outx(:,10)-outx(:,12));
    out_b(:,2)=outx(:,2)-outx(:,5)+(+outx(:,7)-outx(:,8)-outx(:,10)+outx(:,11));
    out_b(:,3)=outx(:,3)-outx(:,6)+(+outx(:,8)-outx(:,9)-outx(:,11)+outx(:,12));
    
    %     out_b(:,1)=outx(:,1)-outx(:,4)-(-outx(:,7)+outx(:,9)+outx(:,10)-outx(:,12));
    %     out_b(:,2)=outx(:,2)-outx(:,5)-(+outx(:,7)-outx(:,8)-outx(:,10)+outx(:,11));
    %     out_b(:,3)=outx(:,3)-outx(:,6)-(+outx(:,8)-outx(:,9)-outx(:,11)+outx(:,12));
    after_flow=netload-out_b;
    out_symbol=zeros(nPeriods,6);
    for i=1:3
        out_symbol(:,i)=outx(:,i)-outx(:,i+3);
        out_symbol(:,i+3)=outx(:,i+6)-outx(:,i+3);
    end
    result_flow=[ sum(before_flow.').'  sum(after_flow.').'];
    cover_plot_r=[outx(:,1) -outx(:,4) -outx(:,7) outx(:,9) outx(:,10) -outx(:,12) pv_out(:,1)*Area_demand(1,1)];
    cover_plot_c=[outx(:,2) -outx(:,5) outx(:,7) -outx(:,8) -outx(:,10) outx(:,11) pv_out(:,2)*Area_demand(1,2)];
    cover_plot_i=[outx(:,3) -outx(:,6) outx(:,8) -outx(:,9) -outx(:,11) outx(:,12) pv_out(:,3)*Area_demand(1,3)];
    fprintf('・MAE\n最適化前：%g\n最適化後：%g\n',string(round(mae(before_flow),4)),string(round(mae(after_flow),4)));
    fprintf('・RMSE\n最適化前：%g\n最適化後：%g\n',string(round(rms(sum(before_flow.').',sum(levelling_level)),4)),string(round(rms(sum(after_flow.').',sum(levelling_level)),4)));
    fprintf('・蓄電池充放電量：%g\n',sum(sum(outx(:,1:6)).'));
    fprintf('・電力融通量：%g\n',sum(sum(outx(:,7:12)).'));
    
    %% 結果・図出力
    filename="LP,ev"+ev_rate+",pv"+pv_rate+'';
    %      filename="LP,ev"+ev_rate+",pv"+pv_rate+",wb"+b_w+"wd"+d_w+'';
    save=0;%1ならば保存する
    figure_out('plot',filename+'SOC推移プロット',socx,[1 25],[0 1],'時刻','State Of Charge',[1.25 0.55 0.25 0.4],["住宅エリア";"商業エリア";"工業エリア"],{'#7030A0','#00B050','#A5A5A5'},'%,.1f',save)
    %figure_out('bar','最適化前flow',before_flow,[0 25],[0 3000],'Time [hour]','Power Flow[kWh]',[1.25 0.3 0.25 0.3],["Residential";"Commercial";"Industrial"],[],save)
    %figure_out('bar','最適化後flow',after_flow,[0 25],[0 3000],'Time [hour]','Power Flow[kWh]',[1.0 0.3 0.25 0.3],["Residential";"Commercial";"Industrial"],[],save)
    figure_out('plot',filename+'最適化結果',result_flow,[0 25],[0 3000],'時刻','配電用変電所からの潮流[kW]',[1.0 0.55 0.25 0.4],["最適化前","最適化後"],{'#C00000','#0000ff'},'%,.0f',save)
    figure_out('heatmap',filename+'充放電状態',outx,[],[],[],'Time [hour]',[1.0 0.0 0.5 0.55],[],[],'',0)
    figure_out('plot_big',filename+'充放電状態プロット',outx(:,1:6),[0 25],[0 1090],'時刻','電力量[kW]',[1.5 0.5 0.5 0.45],["蓄電池放電量（住宅）","蓄電池放電量（商業）","蓄電池放電量（工業）","蓄電池充電量（住宅）","蓄電池充電量（商業）","蓄電池充電量（工業）"],[],'%,.0f',save)
    figure_out('plot_big',filename+'電力融通状態プロット',outx(:,7:12),[0 25],[0 1090],'時刻','電力量[kW]',[1.5 0 0.5 0.45],["エリア間電力融通（住宅→商業）","エリア間電力融通（商業→工業）","エリア間電力融通（工業→住宅）","エリア間電力融通（商業→住宅）","エリア間電力融通（工業→商業）","エリア間電力融通（住宅→工業）"],[],'%,.1f',save)
    
end