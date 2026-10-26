% Вариант 13: y(t) = 6*sin(2*pi*f*t + pi/5), f = 9 Гц
clear; close all; clc;
A = 6;          
f = 9;          
phi = pi/5;     

%% 1-3) Непрерывный сигнал и частота дискретизации
t = 0 : 0.0001 : 3/f;
y = A * sin(2*pi*f*t + phi);
figure;
plot(t, y);
grid on; xlabel('Время, с'); ylabel('Амплитуда'); title('Непрерывный сигнал');
fmax = f; 
fs = 20;

%% 4-6) Оцифровка на 1 секунде и ДПФ
N = fs * 1;                 
td = (0 : N-1) / fs;        
yd = A * sin(2*pi*f*td + phi);

Y = zeros(1, N);
for k = 0:N-1
    summ = 0;
    for n = 0:N-1
        summ = summ + yd(n+1) * exp(-1i*2*pi*k*n/N);
    end
    Y(k+1) = summ;
end

fr = (0 : N-1) * fs / N;    
figure;
subplot(2,1,1);
stem(fr, abs(Y)/N, 'filled');
grid on; xlabel('Частота, Гц'); ylabel('Амплитуда'); title('Спектр, fs = 20 Гц');
subplot(2,1,2);
t_cont = 0:0.0001:1;
plot(t_cont, A * sin(2*pi*f*t_cont + phi)); hold on;
plot(td, yd, 'ro-', 'MarkerSize', 3, 'MarkerFaceColor', 'r');
grid on; xlabel('Время, с'); ylabel('Амплитуда'); title('Восстановление, fs = 20 Гц');

%% 7) Увеличение частоты дискретизации
fs2 = fs * 4;               % 80 Гц
N2 = fs2 * 1;
td2 = (0 : N2-1) / fs2;
yd2 = A * sin(2*pi*f*td2 + phi);

Y2 = zeros(1, N2);
for k = 0:N2-1
    summ = 0;
    for n = 0:N2-1
        summ = summ + yd2(n+1) * exp(-1i*2*pi*k*n/N2);
    end
    Y2(k+1) = summ;
end

fr2 = (0 : N2-1) * fs2 / N2;
figure;
subplot(2,1,1);
stem(fr2, abs(Y2)/N2, 'filled');
grid on; xlabel('Частота, Гц'); ylabel('Амплитуда'); title('Спектр, fs = 80 Гц');
subplot(2,1,2);
plot(t_cont, A * sin(2*pi*f*t_cont + phi)); hold on;
plot(td2, yd2, 'ro-', 'MarkerSize', 3, 'MarkerFaceColor', 'r');
grid on; xlabel('Время, с'); ylabel('Амплитуда'); title('Восстановление, fs = 80 Гц');

%% 9-12) Чтение голоса, прореживание и сохранение
[v, Fs] = audioread('voice.wav');
v = v(:, 1); % На всякий случай берем первый канал
fprintf('Оригинальная частота дискретизации: %d Гц\n', Fs);

v1 = downsample(v, 10);     
Fs_new = Fs / 10; 
fprintf('Новая частота дискретизации после прореживания: %d Гц\n', Fs_new);
audiowrite('voice_downsampled.wav', v1, Fs_new);
disp('Прореженный файл сохранен как voice_downsampled.wav');                 

% Берем фрагмент 4000 отсчетов, иначе цикл повесит Матлаб
frag_orig = min(length(v), 4000); 
v_frag = v(1:frag_orig);
V = zeros(1, frag_orig);

for k = 0:frag_orig-1
    summ = 0;
    for n = 0:frag_orig-1
        summ = summ + v_frag(n+1) * exp(-1i*2*pi*k*n/frag_orig);
    end
    V(k+1) = summ;
end
fv = (0 : frag_orig-1) * Fs / frag_orig;

% То же самое для прореженного файла (400 отсчетов)
frag_down = floor(frag_orig / 10);
v1_frag = v1(1:frag_down);
V1 = zeros(1, frag_down);

for k = 0:frag_down-1
    summ = 0;
    for n = 0:frag_down-1
        summ = summ + v1_frag(n+1) * exp(-1i*2*pi*k*n/frag_down);
    end
    V1(k+1) = summ;
end
fv1 = (0 : frag_down-1) * Fs_new / frag_down;

figure;
subplot(2,1,1);
plot(fv(1:end/2), abs(V(1:end/2)));
grid on; xlabel('Частота, Гц'); ylabel('Модуль спектра'); 
title('Оригинал, fs = 44100 Гц');
subplot(2,1,2);
plot(fv1(1:end/2), abs(V1(1:end/2)), 'm');
grid on; xlabel('Частота, Гц'); ylabel('Модуль спектра'); 
title('После прореживания, fs = 4410 Гц');

%% 13) Разрядность АЦП
figure;
subplot(5,1,1);
stem(fr2, abs(Y2)/N2, 'filled');
grid on; title('Без квантования');

for b = 3:6
    maxv = 2^b - 1;                              
    q = round((yd2 + A) / (2*A) * maxv);         
    yq = q / maxv * 2*A - A;                     
   
    err = mean(abs(yd2 - yq));
    fprintf('АЦП %d бит: уровней = %d, средняя ошибка = %.4f\n', b, 2^b, err);
    
    Yq = zeros(1, N2);
    for k = 0:N2-1
        summ = 0;
        for n = 0:N2-1
            summ = summ + yq(n+1) * exp(-1i*2*pi*k*n/N2);
        end
        Yq(k+1) = summ;
    end
    
    subplot(5,1,b-1);
    stem(fr2, abs(Yq)/N2, 'filled');
    grid on; title(sprintf('%d бит', b));
end
xlabel('Частота, Гц');