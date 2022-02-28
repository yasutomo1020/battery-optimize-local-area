%例題
f=[1;1;];
intcon=[];
A=[];
b=[];
Aeq=[2 1];
beq=[9];
lb=[2;5;];
ub=[10;10;];
options=[];

[x,fval,eflag,out] = intlinprog(f,intcon,A,b,Aeq,beq,lb,ub,options);
fprintf("x1=%d，x2=%d\n",x(1,1),x(2,1));