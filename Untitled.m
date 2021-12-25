i=10000;
% A=rand(i);
% B=rand(i);
% C=zeros(i);
% for j=1:i
%     for k=1:i
%         for l=1:i
%             C(j,l)=A(j,k)*B(k,l);
%         end
%     end
% end
A=2;
B=2;
C=1;
tic
parfor j=1:i
    C=LPfunc(0.00001,0.00001,i);
end
toc

% C=zeros(i);
% tic
% parfor j=1:i
%     C=A*B;
% end
% toc
