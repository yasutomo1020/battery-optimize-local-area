function new_rmse(y,yhat)
% (y - yhat)    % Errors
% (y - yhat).^2   % Squared Error
% mean((y - yhat).^2)   % Mean Squared Error
RMSE = sqrt(mean((y - yhat).^2))  % Root Mean Squared Error
end