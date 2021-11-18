function saveapp
f = uifigure;
ax = uiaxes(f,'Position',[25 25 400 375]);
plot(ax,[0 0.3 0.1 0.6 0.4 1])
b = uibutton(f,'Position',[435 200 90 30],'Text','Save Plot');
b.ButtonPushedFcn = @buttoncallback;

    function buttoncallback(~,~)
        filter = {'*.jpg';'*.png';'*.tif';'*.pdf';'*.eps'};
        [filename,filepath] = uiputfile(filter);
        if ischar(filename)
            exportgraphics(ax,[filepath filename]);
        end
    end
end