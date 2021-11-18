function figure_out_heat(figure_name,data,xlabel_name,ylabel_name,pos)
%図を出力し保存する関数
a=figure('Name',num2str(figure_name),'NumberTitle','on','Units','normalized','OuterPosition',pos);
b=heatmap(data,'xlabel',xlabel_name,'ylabel',ylabel_name) ;
b.YDisplayData = [6:24 1:5];
b.Title = '充放電状態';
% xlim([xll(1) xll(2)])
% ylim([yll(1) yll(2)])
grid on
%pbaspect([2 1 1])
% xticks(0:3:24)
% xticklabels({'6:00','9:00','12:00','15:00','18:00','21:00','0:00','3:00','6:00',})
%legend('Location','northeastoutside')
%exportgraphics(ax,'barchartaxes.png','Resolution',300)
% xlabel(xlabel_name)
% ylabel(ylabel_name)
h=gca;
set(h,'fontsize',12);
%  print(ylabel_name, '-dpng', '-r450')%png image output
img_name=string(inputname(2))+'_heat'+'.png';
exportgraphics(a,img_name,'Resolution',400)
end