
function plot_frequency_group(Chanlocs, freq_group, mask, dat, highlight, colourlim)
% plot_frequency_group plots the mean topography over a frequency group, 
% optionally highlighting significant electrodes using a mask.
dat = mean(dat, 2);
if highlight == true
    mask = logical(sum(mask,2));
    topoplot(dat,Chanlocs,'numcontour',3,'electrodes','on','plotrad',.7,'pmask',mask);
else
    topoplot(dat,Chanlocs,'numcontour',3,'electrodes','on','plotrad',.7);
end
colorbar
caxis(colourlim)
title(sprintf('%.2f-%.2f Hz', min(freq_group), max(freq_group)),'FontSize', 18);

end