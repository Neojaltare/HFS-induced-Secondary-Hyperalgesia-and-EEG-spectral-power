function [n_rows, n_cols, freq_groups] = optimize_subplot_layout(sigfreqs, max_subplots)
% optimize_subplot_layout determines an optimal subplot layout (rows × columns) 
% and groups significant frequencies for visualization, optionally limiting the 
% number of subplots via max_subplots.
    if nargin < 2
        max_subplots = 9;
    end
    
    n_freqs = length(sigfreqs);
    
    if n_freqs <= max_subplots
        % Plot each frequency individually
        n_rows = ceil(sqrt(n_freqs));
        n_cols = ceil(n_freqs / n_rows);
        freq_groups = num2cell(sigfreqs);
    else
        % Group frequencies
        n_rows = ceil(sqrt(max_subplots));
        n_cols = ceil(max_subplots / n_rows);
        
        % Ensure there are no empty groups
        group_size = floor(n_freqs / max_subplots);
        extra = mod(n_freqs, max_subplots);
        
        freq_groups = cell(1, max_subplots);
        start_idx = 1;
        for i = 1:max_subplots
            if extra > 0
                end_idx = start_idx + group_size;
                extra = extra - 1;
            else
                end_idx = start_idx + group_size - 1;
            end
            freq_groups{i} = sigfreqs(start_idx:end_idx);
            start_idx = end_idx + 1;
        end
    end

end


