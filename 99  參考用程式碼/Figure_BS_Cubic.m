clear; clc

%% Support
x_min = 0;                                                                 % Given
x_max = 10;                                                                % Given

NUM = 1001;                                                                % Given

x = linspace(x_min, x_max, NUM);
% clear x_min x_max NUM

%% Setting
% Degree 
n = 3;                                                                     % Given

% Number of Control Points
b = 3;                                                                     % Given                                                            
NUM_CP = 1 + b;

% Number of Knot Points
NUM_KP = 1 + (b + n + 1);

%% Define Knot Points
h = (x(end) - x(1)) / (NUM_KP - 1);                                        % Equally Spaced
x_KP = x(1):h:x(end);

%% Calculate the Cubic B-Spline Basis Function
y_BS = nan(NUM_CP, length(x));                                             % Construct Space

Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';
Path_99 = fullfile(Path_MainFolder, 'Code', '99  參考用程式碼');
addpath(Path_99);

for i = 1:NUM_CP
    for j = 1:length(x)
        y_BS(i, j) = OBJ_BS_Cubic(x(j), h, x_KP(i:(i + n + 1)));
    end
end
clear i j

%% Plot Figure
% Define Color of Each Line
color_All = ['b'; 'g'; 'm'; 'c'; 'y'; 'k'; 'r'];

% Plot Figure: Each Cubic B-Spline Basis Function
for i = 1:NUM_CP
    plot(x, y_BS(i, :), ...
         'LineStyle', '-', ...
         'LineWidth', 2, ...
         'Color', color_All(i))
    hold on
end
grid on

% Plot Figure: A Cubic B-Spline Curve
OPT_CP = rand(NUM_CP, 1);                                                  % Given Instead (Should be Solved)

y = sum(OPT_CP .* y_BS, 1);
plot(x, y, ...
     'LineStyle', ':', ...
     'LineWidth', 5, ...
     'Color', 'r')
hold on

% Legend Setting
for i = 1:(NUM_CP + 1)
    if i < (NUM_CP + 1)
        type_legend{i} = ['$B^{' num2str(n) '}_{' num2str(i - 1) '} (x)$'];
    else
        type_legend{i} = ['$\sum_{i=0}^{' num2str(b) '} \theta_{i} B^{' num2str(n) '}_{i} (x)$'];
    end
end
h = legend(type_legend);
clear type_legend

set(h, 'FontSize', 15, ...
       'FontName', 'Times New Roman', ...
       'FontWeight', 'Bold', ...
       'Interpreter', 'Latex', ...
       'Box', 'Off')
clear h 

set(gca, 'Layer', 'Top')
set(gca, 'LooseInset', get(gca, 'TightInset'))   
% set(gcf, 'Position', get(0, 'ScreenSize'))

% Clear Variable
clear color_All
clear i 
