    clear; clc; close all;
    
    % Исходные данные
    TxPowerBS = 46;        
    TxPowerUE = 24;       
    AntGainBS = 21;       
    PenetrationM = 15;    
    IM = 1;             
    MIMOGain = 3;         % дБ, MIMO 2x2
    FeederLoss = 2 + 0.5 + 0.4;
    
    f_GHz = 1.8;
    f_MHz = f_GHz * 1000;
    BW_UL = 10e6;
    BW_DL = 20e6;         
    NF_BS = 2.4;          
    NF_UE = 6;            
    SINR_UL = 4;          
    SINR_DL = 2;          
    sectors = 3;          
    area_total = 100;     
    area_mall = 4;       
    
    % Бюджет восходящего канала
    TN_UL = -174 + 10*log10(BW_UL);
    RxSens_BS = TN_UL + NF_BS + SINR_UL;
    MAPL_UL = TxPowerUE - FeederLoss + AntGainBS + MIMOGain ...
              - IM - PenetrationM - RxSens_BS;
    
    fprintf('--- 1. Восходящий канал (UL) ---\n');
    fprintf('TN_UL = %.2f дБм\n', TN_UL);
    fprintf('RxSens_BS = %.2f дБм\n', RxSens_BS);
    fprintf('MAPL_UL = %.2f дБ\n\n', MAPL_UL);
    
    % Бюджет нисходящего канала
    TN_DL = -174 + 10*log10(BW_DL);
    RxSens_UE = TN_DL + NF_UE + SINR_DL;
    MAPL_DL = TxPowerBS - FeederLoss + AntGainBS + MIMOGain ...
              - IM - PenetrationM - RxSens_UE;
    
    fprintf('--- 2. Нисходящий канал (DL) ---\n');
    fprintf('TN_DL = %.2f дБм\n', TN_DL);
    fprintf('RxSens_UE = %.2f дБм\n', RxSens_UE);
    fprintf('MAPL_DL = %.2f дБ\n\n', MAPL_DL);
    
    % Пункт 3. Три модели распространения: PL(d)
    d_m = logspace(1, 4, 4000); % расстояние в метрах
    d_km = d_m / 1000;         % расстояние в километрах
    
    % 3.1 UMiNLOS
    PL_uminlos = 26*log10(f_GHz) + 22.7 + 36.7*log10(d_m);
    
    % 3.2 COST231 Hata
    
    hBS = 30; % м, высота антенны базовой станции
    hms = 2;  % м, высота антенны мобильной станции
    A = 46.3;
    B = 33.9;   % диапазон 1500-2000 МГц
    
    a = 3.2 * (log10(11.75*hms))^2 - 4.97;
    Lclutter = 0;
    s_far = 44.9 - 6.55*log10(f_MHz); 
    s_near = (47.88 + 13.9*log10(f_MHz) - 13.9*log10(hBS)) / log10(50);
    s = s_near*ones(size(d_km));
    s(d_km >= 1) = s_far;
    PL_okumura = A + B*log10(f_MHz) - 13.82*log10(hBS) - a + s.*log10(d_km) + Lclutter;
    
    % 3.3 Walfish-Ikegami
    
    dh = 15;   % м, средняя высота зданий
    w = 20;    % м, ширина улиц
    b = 40;    % м, расстояние между зданиями
    phi = 45;  % градусы, угол направления сигнала к улице
    L0 = 32.44 + 20*log10(f_MHz) + 20*log10(d_km);
    % При phi=45 интервал 35..55 градусов
    L_gradus = 2.5 + 0.075*phi;
    L2 = -16.9 - 10*log10(w) + 10*log10(f_MHz) + 20*log10(dh-hms) + L_gradus;
    
    L11 = -18*log10(1 + hBS - dh);
    ka = 54;
    kd = 18;
    kf = -4 + 0.7*(f_MHz/925 - 1);
    L1 = L11 + ka + kd*log10(d_km) + kf*log10(f_MHz) - 9*log10(b);
    PL_wi = L0 + max(L1 + L2, 0);
    
    figure;
    plot(d_km, PL_uminlos, 'r', 'LineWidth', 1.5); hold on; grid on;
    plot(d_km, PL_okumura, 'b', 'LineWidth', 1.5);
    plot(d_km, PL_wi, 'g', 'LineWidth', 1.5);
    plot(d_km, MAPL_UL*ones(size(d_km)), 'm--', 'LineWidth', 1.2);
    plot(d_km, MAPL_DL*ones(size(d_km)), 'k--', 'LineWidth', 1.2);
    xlabel('Расстояние, км');
    ylabel('Потери сигнала PL, дБ');
    title('Модели распространения (Urban, 1.8 ГГц)');
    legend('UMiNLOS', 'COST231 Hata (U)', 'Walfish-Ikegami', ...
           'MAPL UL', 'MAPL DL', 'Location', 'southeast');
    xlim([0 5]);
    
    % Радиус, площадь и количество базовых станций
    % Радиус это точка пересечения PL(d) = MAPL
    if MAPL_UL < min(PL_okumura) || MAPL_DL > max(PL_okumura) || ...
       MAPL_UL < min(PL_uminlos) || MAPL_DL > max(PL_uminlos)
        error('Точка пересечения не входит в диапазон: увеличьте d_m.');
    end
    
    % Макросоты: COST231 Hata
    R_UL_macro = interp1(PL_okumura, d_km, MAPL_UL);
    R_DL_macro = interp1(PL_okumura, d_km, MAPL_DL);
    R_macro = min(R_UL_macro, R_DL_macro);
    
    % Микросоты: UMiNLOS
    R_UL_micro = interp1(PL_uminlos, d_km, MAPL_UL);
    R_DL_micro = interp1(PL_uminlos, d_km, MAPL_DL);
    R_micro = min(R_UL_micro, R_DL_micro);
    
    % S=1.95*R^2
    if sectors ~= 3
        error('Коэффициент площади 1.95 подходит только для 3 секторов.');
    end
    S_macro = 1.95 * R_macro^2;
    S_micro = 1.95 * R_micro^2;
    N_macro = ceil(area_total / S_macro);
    N_micro = ceil(area_mall / S_micro);
    
    fprintf('--- 4. Макросоты (COST231 Hata, Urban) ---\n');
    fprintf('Радиус UL = %.3f км\n', R_UL_macro);
    fprintf('Радиус DL = %.3f км\n', R_DL_macro);
    fprintf('Рабочий радиус = %.3f км\n', R_macro);
    fprintf('Площадь одной БС = %.3f км^2\n', S_macro);
    fprintf('Количество БС на 100 км^2 = %d\n\n', N_macro);
    
    fprintf('--- 4. Микросоты (UMiNLOS) ---\n');
    fprintf('Радиус UL = %.1f м\n', 1000*R_UL_micro);
    fprintf('Радиус DL = %.1f м\n', 1000*R_DL_micro);
    fprintf('Рабочий радиус = %.1f м\n', 1000*R_micro);
    fprintf('Площадь одной БС = %.3f км^2\n', S_micro);
    fprintf('Количество БС на 4 км^2 = %d\n', N_micro);