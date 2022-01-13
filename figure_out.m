function figure_out(type,figure_name,data,xll,yll,xlabel_name,ylabel_name,pos,les,color,yf,save)
%図を出力し保存する関数

if type == "bar"
    a=figure('Name',num2str(figure_name),'MenuBar','none','NumberTitle','on','Units','normalized','OuterPosition',pos);
    bar(data,1,'stacked' ) ; hold on
    if isempty(color)==0
        colororder(color)
    end
    xticks(0:3:24)
    xlim([xll(1) xll(2)])
    ylim([yll(1) yll(2)])
    xticklabels({'6:00','9:00','12:00','15:00','18:00','21:00','0:00','3:00','6:00',})
    xlabel(xlabel_name)
    ylabel(ylabel_name)
    pbaspect([2 1 1])
    h=gca;
  set(h,'fontsize',18,'GridLineStyle',':','GridColor',[10 10 10]/255,'GridAlpha',1,'LineWidth',1,'FontName','ＭＳ 明朝')
    if isempty(les)==0
        %legend(les,'Location','southwest')
        legend(les)
  %      legend('boxoff')
    end
elseif type == "plot"
    a=figure('Name',num2str(figure_name),'ToolBar','none','NumberTitle','on','Units','normalized','OuterPosition',pos);
    plot(data,'LineWidth',3) ; hold on
    if isempty(color)==0
        colororder(color)
    end
    xticks(1:3:25)
    xlim([xll(1) xll(2)])
    ylim([yll(1) yll(2)])
    xticklabels({'6:00','9:00','12:00','15:00','18:00','21:00','0:00','3:00','6:00',})
    xlabel(xlabel_name)
    ylabel(ylabel_name)
    ytickformat(yf)
    pbaspect([2 1 1])
    h=gca;
    set(h,'fontsize',18,'GridLineStyle',':','GridColor',[10 10 10]/255,'GridAlpha',1,'LineWidth',1,'FontName','ＭＳ 明朝')
    if isempty(les)==0
         led=legend(les);
        % legend(les,'Location','southwest')
        led.Color='white';
   %    legend('boxoff')
    end
    pbaspect([1.5 1 1]);
elseif type == "plot_big"
    a=figure('Name',num2str(figure_name),'ToolBar','none','NumberTitle','on','Units','normalized','OuterPosition',pos);
    plot(data,'LineWidth',3) ; hold on
    if isempty(color)==0
        colororder(color)
    end
    xticks(1:3:25)
    xlim([xll(1) xll(2)])
    ylim([yll(1) yll(2)])
    xticklabels({'6:00','9:00','12:00','15:00','18:00','21:00','0:00','3:00','6:00',})
    xlabel(xlabel_name)
    ylabel(ylabel_name)
    pbaspect([2 1 1])
    h=gca;
  set(h,'GridLineStyle',':','GridColor',[10 10 10]/255,'GridAlpha',1,'LineWidth',1,'FontName','ＭＳ 明朝')
    if isempty(les)==0
        % legend(les,'Location','southwest')
        led=legend(les);
        led.NumColumns = 2;
        led.Location='northeast';
        led.FontSize=20;
        led.Color='w';
     %   legend('boxoff')
    end
    set(h,'fontsize',20);
    pbaspect([1.5 1 1]);
elseif type == "heatmap"
    a=figure('Name',num2str(figure_name),'ToolBar','none','NumberTitle','on','Units','normalized','OuterPosition',pos);
    b=heatmap(data,'xlabel',xlabel_name,'ylabel',ylabel_name) ;
    %     b.XDisplayLabels ={'\it P_{R}^{disch}','\it P_{C}^{disch}' ,'\it P_{I}^{disch}', '\it P_{R}^{ch}','\it P_{C}^{ch}' ,'\it P_{I}^{ch}','\it P_{RC}^{dist}','\it P_{CI}^{dist}','\it P_{IR}^{dist}','\it P_{CR}^{dist}','\it P_{IC}^{dist}','\it P_{RI}^{dist}'};
    b.XDisplayLabels ={'\it P_{R}^{disch}','\it P_{C}^{disch}' ,'\it P_{I}^{disch}', '\it P_{R}^{ch}','\it P_{C}^{ch}' ,'\it P_{I}^{ch}','\it P_{RC}^{dist}','\it P_{CI}^{dist}','\it P_{IR}^{dist}','\it P_{CR}^{dist}','\it P_{IC}^{dist}','\it P_{RI}^{dist}'};
    % b.YDisplayData = [6:24 1:5];
    b.YDisplayLabels = [6:24 1:5];
    % b.OuterPosition=[0 0 1 1.2];
    % b.Title = figure_name;
    %b.FontSize = 20;
    b.YLabel=ylabel_name;
    h=gca;
    set(h,'fontsize',28);
    
end
grid on
%legend('Location','northeastoutside')
%exportgraphics(ax,'barchartaxes.png','Resolution',300)
%  print(ylabel_name, '-dpng', '-r450')%png image output
if save==1
    a.OuterPosition=pos*2;
    img_name='figure/'+string(figure_name)+'.emf';
    exportgraphics(a,img_name,'Resolution',500,'ContentType','vector')
    a.OuterPosition=pos;
    disp(string(img_name)+'を保存しました。')
end
set(h,'fontsize',10);
end