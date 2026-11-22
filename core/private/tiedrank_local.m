function r = tiedrank_local(x)
% Ranks with tied values averaged. Matches tiedrank for a vector with no NaNs
% (needed by fmri_corregressor).
[s, i] = sort(x(:));
n = numel(s);
r = zeros(n, 1);
r(i) = 1:n;
k = 1;
while k <= n
    j = k;
    while j < n && s(j+1) == s(k), j = j + 1; end
    if j > k, r(i(k:j)) = mean(k:j); end
    k = j + 1;
end
r = reshape(r, size(x));
end