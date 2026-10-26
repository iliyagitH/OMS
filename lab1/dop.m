% Дополнительное задание: Сдвиг тональности голоса (Фазовый вокодер)
clear; close all; clc;

[y, Fs] = audioread('voice.wav'); 

y_voice = y(:, 1).'; % Берем первый канал и транспонируем в строку
L = length(y_voice);

N_win = round(0.050 * Fs); % Размер окна 50 миллисекунд
N_win = N_win + mod(N_win, 2); % Окно делаем строго четным
step = N_win/2; % Шаг смещения окна (нахлест 50%)
half = N_win/2;
m = 2; % Во сколько раз повышаем голос (2 = мультяшный)

% Окно Ханна, чтобы при склейке не было щелчков на краях
w = 0.5 - 0.5*cos(2*pi*(0:N_win-1)/N_win); 
yp = [y_voice zeros(1, 2*N_win)];
out = zeros(1, L + 2*N_win);

disp('Идет обработка, подожди пару секунд...');

% Цикл по фреймам (кусочкам голоса)
for s = 0:step:L-1
    frame = yp(s+1:s+N_win) .* w;
    Y_frame = fft(frame);
    
    Y_new = zeros(1, N_win);
    for k = 0:half
        kn = round(m*k);
        if kn <= half
            % Главная фишка вокодера: сдвиг частоты + поправка набежавшей фазы
            Y_new(kn+1) = Y_new(kn+1) + Y_frame(k+1) * exp(1i*2*pi*(kn-k)*s/N_win);
        end
    end
    
    % Зеркалим правую половину спектра, чтобы после ifft получились вещественные числа
    for k = 1:half-1
        Y_new(N_win-k+1) = conj(Y_new(k+1));
    end
    
    x_new = real(ifft(Y_new));
    % Склеиваем с наложением (Overlap-Add)
    out(s+1:s+N_win) = out(s+1:s+N_win) + x_new;
end

out = out(1:L);

% Нормируем звук перед сохранением, чтобы не было цифрового перегруза (хрипа)
out = out / max(abs(out)) * 0.9;

disp(['Длительность: было ', num2str(L/Fs), ' с, стало ', num2str(length(out)/Fs), ' с']);

% Сохраняем мультяшный голос в файл
audiowrite('voice_cartoon.wav', out, Fs);
disp('Файл успешно сохранен как voice_cartoon.wav');

disp('Слушаем оригинал...');
z1 = audioplayer(y_voice, Fs); playblocking(z1);

disp('Слушаем мультяшный голос...');
z2 = audioplayer(out, Fs); playblocking(z2);