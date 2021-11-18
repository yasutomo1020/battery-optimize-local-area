function outputArg = rms(inputArg,level)
%入力（1列）の二乗平均誤差を出力する関数
a=(inputArg-level).^2;
outputArg=sqrt(sum(a)/size(a, 1));
end
