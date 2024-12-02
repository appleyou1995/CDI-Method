clear; clc

Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';
Path_Output = fullfile(Path_MainFolder, 'Code', '06  輸出資料');


%% Load Q-measure PDFs

Path_Data_02 = fullfile(Path_MainFolder, 'Code', '02  輸出資料');
Smooth_AllR = [];
Smooth_AllR_RND = [];
years_to_merge = 1996:2021;

for year = years_to_merge    
    input_filename = fullfile(Path_Data_02, sprintf('Output_Tables_%d.mat', year));        
    if exist(input_filename, 'file')
        data = load(input_filename);
        Smooth_AllR = [Smooth_AllR, data.Table_Smooth_AllR];
        Smooth_AllR_RND = [Smooth_AllR_RND, data.Table_Smooth_AllR_RND];
    else
        warning('File %s does not exist.', input_filename);
    end
end

months = Smooth_AllR_RND.Properties.VariableNames;


%% Load P-measure PDFs

Path_Data_06 = fullfile(Path_MainFolder, 'Code', '06  輸出資料');

load(fullfile(Path_Data_06, 'b_4_AllR_PDF.mat'));
load(fullfile(Path_Data_06, 'b_6_AllR_PDF.mat'));
load(fullfile(Path_Data_06, 'b_8_AllR_PDF.mat')');

b_values = [4, 6, 8];
AllR_PD_Tables = {b_4_AllR_PDF, b_6_AllR_PDF, b_8_AllR_PDF};


%% Plot: PDF Under Q Measure

figure;
hold on;

area_sums_Q = zeros(1, length(months));

for t = 1:length(months)
    
    x_values = Smooth_AllR{1, months{t}};
    y_values = Smooth_AllR_RND{1, months{t}};
    
    area_sums_Q(t) = trapz(x_values, y_values);

    plot(x_values, y_values);

end

grid on;
hold off;

title('Probability Density Function Under Q Measure');
xlabel('Gross Return');
ylabel('Probability Density');
    
xlim([0, 3.1]);

filename = 'Q_Measure_PDF.png';
saveas(gcf, fullfile(Path_Output, filename));


%% Plot: PDF Under P Measure

figure = tiledlayout(1, 3, 'TileSpacing', 'Compact', 'Padding', 'Compact');

for idx_b = 1:length(b_values)

    b = b_values(idx_b);
    P_Table = AllR_PD_Tables{idx_b};
    
    nexttile;
    hold on;

    for t = 1:length(months)
        x_values = Smooth_AllR{1, months{291}};                            % 291: max gross return month (20200318)
        y_values = P_Table(t, :);
        plot(x_values, y_values);
    end

    grid on;
    hold off;

    title(['b = ' num2str(b)]);
    xlabel('Gross Return');
    ylabel('Probability Density');

    xlim([0, 3.1]);
    ylim([0, 25]);

end

sgtitle('Probability Density Function Under P Measure');

set(gcf, 'Position', [100, 100, 1400, 400]);

filename = 'P_Measure_PDF.png';
saveas(gcf, fullfile(Path_Output, filename));


%% Plot: CDF Under Q Measure

figure;
hold on;

for t = 1:length(months)
    
    x_values = Smooth_AllR{1, months{t}};
    
    pdf_values = Smooth_AllR_RND{1, months{t}};
    cdf_values = cumsum(pdf_values) / sum(pdf_values);
    
    plot(x_values, cdf_values);
end

grid on;
hold off;

title('Cumulative Distribution Function Under Q Measure');
xlabel('Gross Return');
ylabel('Cumulative Probability');
xlim([0, 3.1]);
ylim([0, 1.05]);

filename = 'Q_Measure_CDF.png';
saveas(gcf, fullfile(Path_Output, filename));


%% Plot: CDF Under P Measure

figure = tiledlayout(1, 3, 'TileSpacing', 'Compact', 'Padding', 'Compact');

for idx_b = 1:length(b_values)
    
    b = b_values(idx_b);
    P_Table = AllR_PD_Tables{idx_b};
    
    nexttile;
    hold on;

    for t = 1:length(months)

        x_values = Smooth_AllR{1, months{t}};
        
        pdf_values = P_Table(t, :);
        cdf_values = cumsum(pdf_values) / sum(pdf_values);

        plot(x_values, cdf_values);
    end

    grid on;
    hold off;

    title(['b = ' num2str(b)]);
    xlabel('Gross Return');
    ylabel('Cumulative Probability');

    xlim([0, 3.1]);
    ylim([0, 1.05]);

end

sgtitle('Cumulative Distribution Function Under P Measure');

set(gcf, 'Position', [100, 100, 1400, 400]);

filename = 'P_Measure_CDF.png';
saveas(gcf, fullfile(Path_Output, filename));

