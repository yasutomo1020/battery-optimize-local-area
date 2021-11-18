%% button
fig = uifigure('Name','Tools','Units','normalized','Position',[1.2 0.7 0.15 0.2]);
fig.CloseRequestFcn = @(fig,event)my_closereq(fig);
%  fig.WindowButtonMotionFcn = @(fig)mouseMoved(fig);
    btnX = 50;
    btnY = 100;
    btnWidth = 200;
    btnHeight = 40;
    
btn = uibutton(fig,'push','Text','Close all','Position',[btnX,btnY, btnWidth, btnHeight],'FontSize',20,'FontWeight','bold','FontColor','white','BackgroundColor','red','ButtonPushedFcn', @(btn,event) plotButtonPushed1(btn));

%btn2 = uibutton(fig,'push','Text','Close all','Position',[50,50, 200, 40],'FontSize',20,'FontWeight','bold','FontColor','white','BackgroundColor','red','ButtonPushedFcn', @(btn,event) plotButtonPushed2(btn));
function plotButtonPushed1(btn)
close all
%     close Tools
end
function plotButtonPushed2(btn2)
close all
%     close Tools
end
function my_closereq(fig,selection)
selection = uiconfirm(fig,'ウィンドウを閉じますか？','Confirmation');
switch selection
    case 'OK'
        delete(fig)
    case 'Cancel'
        return
end
end
% function mouseMoved(fig,btnX,btnY,btnWidth,btnHeight)
%           mousePos = fig.CurrentPoint;
%           if  (mousePos(1) >= btnX) && (mousePos(1) <= btnX + btnWidth) ...
%                         && (mousePos(2) >= btnY) && (mousePos(2) <= btnY + btnHeight)
%               fig.Pointer = 'hand';
%           else
%               fig.Pointer = 'arrow';
%           end
% end
