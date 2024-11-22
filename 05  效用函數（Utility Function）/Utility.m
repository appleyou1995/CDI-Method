clear; clc

Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';
Path_Data_05 = fullfile(Path_MainFolder, 'Code', '05  效用函數（Utility Function）');

addpath(Path_Data_05);

w = linspace(0.8, 1.2, 100);


%% [Utility] One Switch - Linear plus Exponential

a = -5;
b = -1;
c = -8;

One_Switch_Linear_plus_Exponential = @(w) a * w + b * exp(c * w);

[ARA, RRA, AP, RP, AT, RT] = Risk_Preference(One_Switch_Linear_plus_Exponential, w);

fprintf('One Switch - Linear plus Exponential\n');
Print_Coefficients([a, b, c], {'a', 'b', 'c'});
Display_Slope_Trend(ARA, RRA, AP, RP, AT, RT, w);


%% [Utility] One Switch - Linear times Exponential

a = 1;
b = 1;
c = 1;

One_Switch_Linear_times_Exponential = @(w) (a * w + b) .* exp(c * w);

[ARA, RRA, AP, RP, AT, RT] = Risk_Preference(One_Switch_Linear_times_Exponential, w);

fprintf('One Switch - Linear times Exponential\n');
Print_Coefficients([a, b, c], {'a', 'b', 'c'});
Display_Slope_Trend(ARA, RRA, AP, RP, AT, RT, w);


%% [Utility] Expo-Power

alpha = -1;
r = -0.5;

Expo_Power = @(w) (1 - exp(-alpha * w.^(1 - r))) / alpha;

[ARA, RRA, AP, RP, AT, RT] = Risk_Preference(Expo_Power, w);

fprintf('Expo-Power\n');
Print_Coefficients([alpha, r], {'alpha', 'r'});
Display_Slope_Trend(ARA, RRA, AP, RP, AT, RT, w);


%% [Utility] Linear plus Power

k = -3;
gamma = 2;

Linear_plus_Power = @(w) k*w + (w.^(1-gamma))/(1-gamma);

[ARA, RRA, AP, RP, AT, RT] = Risk_Preference(Linear_plus_Power, w);

fprintf('Linear plus Power\n');
Print_Coefficients([k, gamma], {'k', 'gamma'});
Display_Slope_Trend(ARA, RRA, AP, RP, AT, RT, w);


%% Plot

figure;
subplot(2, 3, 1);
plot(w, ARA); title('Absolute Risk Aversion (ARA)');
xlabel('w'); ylabel('ARA');

subplot(2, 3, 4);
plot(w, RRA); title('Relative Risk Aversion (RRA)');
xlabel('w'); ylabel('RRA');

subplot(2, 3, 2);
plot(w, AP); title('Absolute Prudence (AP)');
xlabel('w'); ylabel('AP');

subplot(2, 3, 5);
plot(w, RP); title('Relative Prudence (RP)');
xlabel('w'); ylabel('RP');

subplot(2, 3, 3);
plot(w, AT); title('Absolute Temperance (AT)');
xlabel('w'); ylabel('AT');

subplot(2, 3, 6);
plot(w, RT); title('Relative Temperance (RT)');
xlabel('w'); ylabel('RT');

set(gcf, 'Position', [100, 100, 1000, 600]);