function Display_Slope_Trend(ARA, RRA, AP, RP, AT, RT, w)
    
    dw = diff(w);
    ARA_slope = diff(ARA) ./ dw;
    RRA_slope = diff(RRA) ./ dw;
    AP_slope  = diff(AP) ./ dw;
    RP_slope  = diff(RP) ./ dw;
    AT_slope  = diff(AT) ./ dw;
    RT_slope  = diff(RT) ./ dw;

    ARA_trend = determine_trend(ARA_slope);
    RRA_trend = determine_trend(RRA_slope);
    AP_trend  = determine_trend(AP_slope);
    RP_trend  = determine_trend(RP_slope);
    AT_trend  = determine_trend(AT_slope);
    RT_trend  = determine_trend(RT_slope);

    fprintf('ARA slope: %s\n', ARA_trend);
    fprintf('RRA slope: %s\n', RRA_trend);
    fprintf(' AP slope: %s\n', AP_trend);
    fprintf(' RP slope: %s\n', RP_trend);
    fprintf(' AT slope: %s\n', AT_trend);
    fprintf(' RT slope: %s\n', RT_trend);
    fprintf('- - - - - - - - - - - - - - - - - - -\n');
end


function trend = determine_trend(slope)

    if all(slope > 0)
        trend = "Increasing";

    elseif all(slope < 0)
        trend = "Decreasing";

    elseif all(abs(slope) < 1e-6)
        trend = "Constant";

    else
        trend = "Mixed";
    end
end