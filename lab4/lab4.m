% Лабораторная работа 4 (нечётная группа, рис. 4.5, номер 12)
clear; clc; close all;

N = 31;

x1 = [0 1 1 0 0];
y1 = [1 0 0 1 1];

x2 = [0 1 1 0 1];
y2 = [0 1 1 1 0];

seq1 = gold_seq(x1, y1, N);
seq2 = gold_seq(x2, y2, N);

disp('Последовательность 1:');
disp(seq1);
disp('Последовательность 2:');
disp(seq2);

% 2) Автокорреляция через autocorr()
ac = autocorr(seq1, 'NumLags', N - 1);

disp('Сдвиг | autocorr');
for k = 0:N-1
    fprintf('%5d | %.4f\n', k, ac(k + 1));
end

% 3-4) Взаимная корреляция через xcorr() (переводим 0 -> -1, 1 -> +1)
b1 = 2 * seq1 - 1;
b2 = 2 * seq2 - 1;

[cc, lags_cc] = xcorr(b1, b2, 'coeff');
fprintf('\nВзаимная корреляция (lag = 0): %.4f\n', cc(lags_cc == 0));

[ac_xcorr, lags_x] = xcorr(b1, 'coeff');

figure;

subplot(2, 1, 1);
stem(0:N-1, ac, 'filled');
grid on;
xlabel('Lag');
ylabel('Автокорреляция');
title('Автокорреляция (autocorr)');

subplot(2, 1, 2);
stem(lags_x, ac_xcorr, 'filled');
grid on;
xlabel('Lag');
ylabel('Автокорреляция');
title('Автокорреляция (xcorr)');

% Функция генерации последовательности Голда по схеме 4.5
function seq = gold_seq(x, y, N)
    seq = zeros(1, N);
    for t = 1:N
        seq(t) = xor(x(5), y(5));
        new_x = xor(x(4), x(5));
        new_y = xor(y(2), y(5));

        x = [new_x, x(1:4)];
        y = [new_y, y(1:4)];
    end
end