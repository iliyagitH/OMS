#include <iostream>
#include <iomanip>
using namespace std;

const int N = 31;

void makeGold(const int x_init[5], const int y_init[5], int out[N]) {
    int x[5], y[5];
    for (int i = 0; i < 5; i++) {
        x[i] = x_init[i];
        y[i] = y_init[i];
    }

    for (int step = 0; step < N; step++) {
        out[step] = x[4] ^ y[4];

        int new_x = x[3] ^ x[4]; // x4 XOR x5
        int new_y = y[1] ^ y[4]; // y2 XOR y5

        for (int i = 4; i > 0; i--) {
            x[i] = x[i - 1];
            y[i] = y[i - 1];
        }
        x[0] = new_x;
        y[0] = new_y;
    }
}

int main() {

    int x1[5] = {0, 1, 1, 0, 0}; 
    int y1[5] = {1, 0, 0, 1, 1}; 

    int x2[5] = {0, 1, 1, 0, 1};
    int y2[5] = {0, 1, 1, 1, 0};

    int seq1[N], seq2[N];
    makeGold(x1, y1, seq1);
    makeGold(x2, y2, seq2);

    cout << "Последовательность 1: ";
    for (int i = 0; i < N; i++) cout << seq1[i] << " ";
    cout << endl << endl;

    // 2) Циклический сдвиг вправо и автокорреляция
    cout << "Сдвиг | Последовательность                                            | Автокорреляция" << endl;
    cout << "--------------------------------------------------------------------------------------" << endl;

    double min_ac = 1.0, max_ac = -1.0;

    for (int shift = 0; shift <= N; shift++) {
        int shifted[N];
        int match = 0;

        for (int i = 0; i < N; i++) {
            shifted[i] = seq1[(i - shift + N) % N];
            if (seq1[i] == shifted[i]) {
                match++;
            }
        }

        int mismatch = N - match;
        double autocorr = (double)(match - mismatch) / N;

        if (shift > 0 && shift < N) {
            if (autocorr < min_ac) min_ac = autocorr;
            if (autocorr > max_ac) max_ac = autocorr;
        }

        cout << setw(5) << shift << " | ";
        for (int i = 0; i < N; i++) cout << shifted[i] << " ";
        cout << "| " << fixed << setprecision(4) << autocorr << endl;
    }
    cout << endl;

    cout << "Последовательность 2: ";
    for (int i = 0; i < N; i++) cout << seq2[i] << " ";
    cout << endl;

    // 4) Взаимная корреляция seq1 и seq2
    int match = 0;
    for (int i = 0; i < N; i++) {
        if (seq1[i] == seq2[i]) {
            match++;
        }
    }
    int mismatch = N - match;
    double cross = (double)(match - mismatch) / N;

    cout << "Взаимная корреляция: " << fixed << setprecision(4) << cross << endl << endl;

    // Свойство 1: сбалансированность
    int ones = 0;
    for (int i = 0; i < N; i++) {
        if (seq1[i] == 1) ones++;
    }
    int zeros = N - ones;
    cout << "1. Сбалансированность: единиц = " << ones << ", нулей = " << zeros;
    if (abs(ones - zeros) <= 1) cout << " (выполняется)" << endl;
    else cout << " (НЕ выполняется)" << endl;

    // Свойство 2: цикличность
    int runs[N + 1] = {0};
    int total_runs = 0;
    int len = 1;
    for (int i = 1; i < N; i++) {
        if (seq1[i] == seq1[i - 1]) {
            len++;
        } else {
            runs[len]++;
            total_runs++;
            len = 1;
        }
    }
    runs[len]++;
    total_runs++;

    cout << "2. Цикличность (всего циклов = " << total_runs << "):" << endl;
    for (int l = 1; l <= N; l++) {
        if (runs[l] > 0) {
            cout << "   длина " << l << ": " << runs[l] << " шт. ("
                 << fixed << setprecision(1) << 100.0 * runs[l] / total_runs << "%)" << endl;
        }
    }

    // Свойство 3: корреляция на ненулевых сдвигах (1..30)
    cout << "3. Корреляция (сдвиги 1..30): min = " << fixed << setprecision(4) << min_ac
         << ", max = " << max_ac << endl;

    return 0;
}