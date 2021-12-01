function [] = heat(figure_name,data,xlabel_name,ylabel_name,pos,xdislab,save)
%HEATMAP この関数の概要をここに記述
%   詳細説明をここに記述
   a=figure('Name',num2str(figure_name),'NumberTitle','on','Units','normalized','OuterPosition',pos);
    b=heatmap(data,'xlabel',xlabel_name,'ylabel',ylabel_name) ;
    b.XDisplayLabels=xdislab;
   %     b.XDisplayLabels ={'\it P_{R}^{disch}','\it P_{C}^{disch}' ,'\it P_{I}^{disch}', '\it P_{R}^{ch}','\it P_{C}^{ch}' ,'\it P_{I}^{ch}','\it P_{RC}^{dist}','\it P_{CI}^{dist}','\it P_{IR}^{dist}','\it P_{CR}^{dist}','\it P_{IC}^{dist}','\it P_{RI}^{dist}'};
   % b.XDisplayLabels ={'\it P_{R}^{disch}','\it P_{C}^{disch}' ,'\it P_{I}^{disch}', '\it P_{R}^{ch}','\it P_{C}^{ch}' ,'\it P_{I}^{ch}','\it P_{RC}^{dist}','\it P_{CI}^{dist}','\it P_{IR}^{dist}','\it P_{CR}^{dist}','\it P_{IC}^{dist}','\it P_{RI}^{dist}','\it z','\it P_{R}^{busdisch}','\it P_{C}^{busdisch}','\it P_{I}^{busdisch}','\it P_{R}^{busch}','\it P_{C}^{busch}','\it P_{I}^{busch}'};
   % b.YDisplayData = [6:24 1:5];
   b.YDisplayLabels = [6:24 1:5];
  % b.OuterPosition=[0 0 1 1.2];
   % b.Title = figure_name;
    %b.FontSize = 20;
    b.YLabel=ylabel_name;
    h=gca;
    set(h,'fontsize',13);
        a.OuterPosition=pos*2;
    img_name=string(figure_name)+'.emf';
    exportgraphics(a,img_name,'Resolution',500,'ContentType','vector')
    a.OuterPosition=pos;
    set(h,'fontsize',12);
    disp(string(img_name)+'を保存しました。')
end

