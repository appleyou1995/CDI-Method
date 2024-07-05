function AllR_PD = Physical_Density(Smooth_ALLR, Smooth_AllR_RND, All_g_hat)
    
    months = Smooth_ALLR.Properties.VariableNames;
    T = length(months);
    AllR_PD = table();

    for t = 1:T

        current_month_RND = Smooth_AllR_RND{1, months{t}};
        current_month_g_hat = All_g_hat{1, months{t}};
                
        current_month_PD = current_month_RND .* current_month_g_hat;

        columnName = num2str(months{t});
        AllR_PD.(columnName) = current_month_PD;

    end
    
end