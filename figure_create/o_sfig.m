function o_sfig(rate,xll,yll,X1,xlabelname,ylabelname,filename1,filename2,xlab,ylab)
%% 関数説明
% 1. 縦横比
% 2. フォント(Times New Roman), フォントサイズ
% 3. Grid (パワポでemfを編集するときにグリッドが変にならないようにしました。)
% --- 変数説明 ---
% rate:比の設定
% yll,xll:軸の範囲指定
% X:塗る範囲
% filename1: 図の保存名
% filename2: ファイル名
% xlab,ylab:軸名
%%
   if ~exist('filename', 'var') || isempty(filename)
       filename='fig1.emf';
   end
%% 文字の大きさ
ax = gca;%軸のプロパティを取得 gca: get current axis
font_name='Times New Roman'; %軸のフォント設定
set(ax,'FontName',font_name)
% if rate == 1
    ax.XAxis.FontSize = 9;
    ax.YAxis(1).FontSize = 9;
    if length(ax.YAxis) == 2
    ax.YAxis(2).FontSize = 9;
    end
% else
%     ax.XAxis.FontSize = 18;
%     ax.YAxis(1).FontSize = 18;
%     if length(ax.YAxis) == 2
%     ax.YAxis(2).FontSize = 18;
%     end
% end
    
%% 図の範囲指定
   if ~exist('xll', 'var') || isempty(xll) %x軸の範囲指定がない場合
        ax1=gcf;
        ax1 = ax1.Children;
        x1 = ax1.Children.XData;
        xh = max(x1);
        xl = min(x1);
        xlim([xl xh])
   else
         xl=xll(1);xh=xll(2);  
         xlim([xl xh])
   end

   
if ~exist('yll', 'var') || isempty(yll) %y軸の範囲指定がない場合
        ax1 = gca;
        ax2 = gcf;
        ylim([ax1.YLim(1) ax1.YLim(2)])
else
    ylim([yll(1) yll(2)])
end
%% 比の設定
pbaspect([rate 1 1])
    %% PPT用
% pbaspect([4.35/10 2.9/10 1])
%%
grid on
% P_CA
set(gcf,'Color','none'); % figureの背景を透明に設定
set(gca,'Color','none'); % axisの背景を透明に設定
set(gca, 'LooseInset', get(gca, 'TightInset'));%余白小さく
set(gca,'GridLineStyle',':',... % グリッドの線種を点線に設定
           'GridColor',[10 10 10]/255,... % グリッド線の色を黒に設定
           'GridAlpha',1,'LineWidth',1) % 透過性を.3，グリッド線の太さを.5に設定
%% x,yラベルの名前
if isempty(xlabelname) == 0
    xlabel(xlabelname)
end
if isempty(ylabelname) == 0
    ylabel(ylabelname)
end
%% 枠の太字
% box_line
box_line
%% 塗りつぶし
if isempty(X1) == 0
ax2 = gca;
yl = ax2.YLim(1);
yh = ax2.YLim(2);
NURU(3600*X1(1),3600*X1(2),yl,yh)
end
%% ファイルの移動
ZUCD
if exist(filename2) ~= 7
mkdir(filename2)
end
cd(filename2)
       %% 図の保存
% saveas(gca,filename)
filename1 = [filename1,'.emf'];
print('-painters','-dmeta','-r600',filename1)%分割されるときはexportfigure,または直接エクスポートを選択
% print('-painters','-deps','myVectorFile')
%%
set(gcf,'Color','w'); % figureの背景を白に設定
set(gca,'Color','w'); % axisの背景を白に設定
%% ファイルの移動
MOTOCD
end
 