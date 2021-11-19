f=[0 0 1];
intcon=[];
A=[1 -1 -1;-1 1 0];
b=[0;0];
Aeq=[];
beq=[];
lb=[0 0 -Inf];
ub=[100 100 Inf];
options= optimoptions('intlinprog','RootLPAlgorithm','primal-simplex');
%options=[];
tic
[x,fval,eflag,out] = intlinprog(f,intcon,A,b,Aeq,beq,lb,ub,options);
toc