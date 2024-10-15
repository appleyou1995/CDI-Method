function AllR_PD = Physical_Density(Smooth_ALLR, Smooth_AllR_RND, All_g_hat)

    months = Smooth_ALLR.Properties.VariableNames;
    AllR_PD = table();

    for t = 1:length(months)
        
        current_month_PD = Smooth_AllR_RND{1, months{t}} .* All_g_hat{1, months{t}};
        AllR_PD.(months{t}) = current_month_PD;
        
    end
end
