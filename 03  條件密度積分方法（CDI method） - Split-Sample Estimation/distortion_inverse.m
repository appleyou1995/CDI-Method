%% Distortion Function Inverse

function D_inv = distortion_inverse(x, alpha, beta)

    D_inv = exp(-(-log(x)).^(1/alpha) / beta);

end