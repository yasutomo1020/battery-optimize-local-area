function figure_out_plot(figure_name,data,xll,yll,xlabel_name,ylabel_name,pos,les)
%図を出力し保存する関数
a=figure('Name',num2str(figure_name),'NumberTitle','on','Units','normalized','OuterPosition',pos);
plot(data,'LineWidth',2) ; hold on
xlim([xll(1) xll(2)])
ylim([yll(1) yll(2)])
grid on
pbaspect([2 1 1])
%xticks(1:3:25)
xticks(1:3:25)
xticklabels({'6:00','9:00','12:00','15:00','18:00','21:00','0:00','3:00','6:00',})
%legend('Location','northeastoutside')
%exportgraphics(ax,'barchartaxes.png','Resolution',300)
xlabel(xlabel_name)
ylabel(ylabel_name)
h=gca;
if isempty(les)==0
    legend(les)
end
set(h,'fontsize',10);
%  print(ylabel_name, '-dpng', '-r450')%png image output
img_name=string(ylabel_name)+'.png';
exportgraphics(a,img_name,'Resolution',400)
end