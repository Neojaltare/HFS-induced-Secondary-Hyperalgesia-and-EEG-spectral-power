
function plot_single_frequency(Chanlocs, freq_group, mask, dat, highlight, colourlim)
% plot_single_frequency plots the topography for a single frequency, 
% with optional masking to highlight significant electrodes.
    
    if highlight == true
       topoplot(dat,Chanlocs,'numcontour',3,'electrodes','on','plotrad',.7,'pmask',mask);
    else
       topoplot(dat,Chanlocs,'numcontour',3,'electrodes','on','plotrad',.7,'conv','off');
    end
    colorbar
    caxis(colourlim)
    title(sprintf('%.2f Hz', freq_group),'FontSize', 18);

end
