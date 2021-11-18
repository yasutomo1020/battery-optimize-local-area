%% 線形計画法チュートリアル(価格を最小化)
clear;

%% ヘッダー
disp('---------------------------------------------------------------------------------------')
dt = datetime('now');
DateString = datestr(dt,'yyyy年mm月dd日HH時MM分ss秒FFF');
disp(DateString)

%% 変数に代入
load('lp_testdata.mat', '-mat');
lp_data_array = table2array(lp_data);
iii = 1;
for iii=1:size(lp_data_array) 
    cost_data(iii)=str2double(lp_data_array(iii, 2));%値段
    intcon(iii) =(iii);
end
for iii=1:size(lp_data_array) 
    cal_data(iii)=str2double(lp_data_array(iii, 3));%カロリー
end
for iii=1:size(lp_data_array) 
    pro_data(iii)=str2double(lp_data_array(iii, 4));%タンパク質
end

budget = 500;%予算（円）
need_cal = 700;%必要なカロリー（cal）
need_pro = 20;%必要なタンパク質（g）
A = [cost_data;-cal_data;-pro_data;];
b = [budget;-need_cal;-need_pro;];
f = cost_data.';
lb = zeros(size(f, 1) ,1);%解の下限
ub =Inf(size(f, 1) ,1);%解の上限
Aeq = [];%等式条件（左辺）
beq =[];%等式条件（右辺）

%% 最適化（線形計画法）
[x,fval,exitflag,output] = intlinprog(f,intcon,A,b,Aeq,beq,lb,ub);%ｆの最小値を条件をもとに計算
cst=0;
cal=0;
pro=0;

%% 結果表示
for iii=1:size(f, 1) 
    if round(x(iii)) ~= 0
        disp(lp_data_array(iii, 1)+'を'+round(x(iii))+'個')
        cst = cst + cost_data(iii) * round(x(iii));
        cal = cal + cal_data(iii) * round(x(iii));
         pro = pro + pro_data(iii) * round(x(iii));
    end
end
disp('合計金額：'+string(cst)+'円、合計カロリー：'+string(cal)+'cal、合計タンパク質：'+string(pro)+'g')

 %% 練習
% f = [2;3];%最小化したい関数を作成
% intcon = [1, 2];%整数に限定したい項を指定
% A = [1, 0];%不等式条件（左辺）Ａｘ≤ｂ
% b = 4;%不等式条件（右辺）
% Aeq = [1,1];%等式条件（左辺）
% beq =10;%等式条件（右辺）
% lb = zeros(2,1);%解の下限
% ub = [Inf;Inf];%解の上限
% [x,fval,exitflag,output] = intlinprog(f,intcon,A,b,Aeq,beq,lb,ub)%ｆの最小値を条件をもとに計算
