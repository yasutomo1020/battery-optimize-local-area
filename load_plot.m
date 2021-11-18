load('const.mat','demand_data')
close all;
pos=[1.0 0.0 0.4 0.5];
 fig=figure('Units','normalized','OuterPosition',pos);
set(fig,'defaultAxesColorOrder',[[0 0 0];[0 0 0]])
r=demand_data(:,1);
c=demand_data(:,2);
i=demand_data(:,3);

%% ci
plot(c,'Color','r','LineWidth',3)
hold on
plot(i,'Color',[230/255 230/255 0],'LineWidth',3)
ylim([0 27])
ylabel('商業・工業負荷[kW]')
%% r
yyaxis right
plot(r,'Color','b','LineWidth',3)
ylim([0 1.2])
grid on
xticks(1:3:25)
xlabel('Time [hour]')
ylabel('住宅負荷[kW]')
%    xlim([0 25])
%    yll=[0 30];
%     xlim([xll(1) xll(2)])
%     ylim([yll(1) yll(2)])
xticklabels({'6:00','9:00','12:00','15:00','18:00','21:00','0:00','3:00','6:00',})
h=gca;
set(h,'fontsize',14);
set(gca,'GridLineStyle',':',... % グリッドの線種を点線に設定
    'GridColor',[10 10 10]/255,... % グリッド線の色を黒に設定
    'GridAlpha',1,'LineWidth',1) % 透過性を.3，グリッド線の太さを.5に設定
legend(["住宅";"商業";"工業"])
img_name='load_plot.emf';
exportgraphics(fig,img_name,'Resolution',500,'ContentType','vector')
disp(string(img_name)+'を保存しました。')