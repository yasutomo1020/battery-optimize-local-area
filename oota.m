load oota_data.mat;
nPeriods=24;
oota_pv_1h=zeros(size(PV_AC,1),size(PV_AC,2)+1);
PV_AC_mov=zeros(size(PV_AC));
for i=1:size(PV_AC,1)
    for j=1:size(PV_AC,2)
        if PV_AC(i,j) <= 0
            PV_AC_mov(i,j)=0;
        else
            PV_AC_mov(i,j)=PV_AC(i,j);
        end       
    end
end
PV_AC_mov = standardizeMissing(PV_AC_mov,0);
PV_AC_mov=fillmissing(PV_AC_mov,'movmean',[size(PV_AC,2) size(PV_AC,2)],2);
for i=1:numel(date)
    for j=1:nPeriods
            oota_pv_1h(j+(i-1)*nPeriods,1)=j-1;
        oota_pv_1h(j+(i-1)*nPeriods,2:size(PV_AC,2)+1)=PV_AC_mov(j+(i-1)*nPeriods,:);
    end
    oota_pv_1h(nPeriods*(i-1)+1,1)=date(i,1);
end
oota_2007_mean(:,1)=oota_pv_2007(:,1);
oota_2007_mean(:,2)=mean(oota_pv_2007(:,2:end).').';
% oota_pv_1h(isnan(oota_pv_1h))=0;