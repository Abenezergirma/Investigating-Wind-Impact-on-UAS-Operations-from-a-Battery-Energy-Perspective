%clc
%clear

% Финальные значения параметров
fa = 1;
fJ = 1;
fv = 4;
fT = 14;
step = 0.01;

% Сивольные переменные
syms a v J T t i i1 i2 i3 i4 i5 i6 i7 i8


% Вывод формул на каждом интервале
i1 = 0;
d3s_1   = J;
d2s_1   = simplify(int(d3s_1,t));
ds_1    = simplify(int(d2s_1,t));
s_1     = simplify(int(ds_1,t));
    
i2      = a/(J);
d3s_2   = 0;
d2s_2   = a;
ds_2    = simplify(int(d2s_2,t)+ ( subs(ds_1,t,i2) - subs(int(d2s_2,t),t,i2) ));
s_2     = simplify(int(ds_2,t)+ ( subs(s_1,t,i2) - subs(int(ds_2,t),t,i2) ));

i3      =  v/(a);
d3s_3   = -J;
d2s_3   = simplify(int(d3s_3,t)+ (subs(d2s_2,t,i3) - subs(int(d3s_3,t),t,i3)));
ds_3    = simplify(int(d2s_3,t)+ (subs(ds_2,t,i3) - subs(int(d2s_3,t),t,i3)));
s_3     = simplify(int(ds_3,t)+ (subs(s_2,t,i3) - subs(int(ds_3,t),t,i3)));

i4      = v/a+a/J;
d3s_4   = 0;
d2s_4   = 0;
ds_4    = v;
s_4     = simplify(int(ds_4,t)+ (subs(s_3,t,i4) - subs(int(ds_4,t),t,i4)));

i5      = T-v/a-a/J;
d3s_5   = -J;
d2s_5   = simplify(int(d3s_5,t)+ (subs(d2s_4,t,i5) - subs(int(d3s_5,t),t,i5)));
ds_5    = simplify(int(d2s_5,t)+ (subs(ds_4,t,i5) - subs(int(d2s_5,t),t,i5)));
s_5     = simplify(int(ds_5,t)+ (subs(s_4,t,i5) - subs(int(ds_5,t),t,i5)));

i6      = T - v/a;
d3s_6   = 0;
d2s_6   = -a;
ds_6    = simplify(int(d2s_6,t)+ (subs(ds_5,t,i6) - subs(int(d2s_6,t),t,i6)));
s_6     = simplify(int(ds_6,t)+ (subs(s_5,t,i6) - subs(int(ds_6,t),t,i6)));

i7      = T - a/J;
d3s_7   = J;
d2s_7   = simplify(int(d3s_7,t)+ (subs(d2s_6,t,i7) - subs(int(d3s_7,t),t,i7)));
ds_7    = simplify(int(d2s_7,t)+ (subs(ds_6,t,i7) - subs(int(d2s_7,t),t,i7)));
s_7     = simplify(int(ds_7,t)+ (subs(s_6,t,i7) - subs(int(ds_7,t),t,i7)));


% Подсчет значений на каждом интервале, 
% можно было бы короче, но функция не хотела возвращать вектор столбец
int1 = 0:step:sub(i2, a, fa, J, fJ, v, fv, T, fT, t, 0);
[S, dS, d2S, d3S] = f(s_1,ds_1,d2s_1,d3s_1, a, fa, J, fJ, v, fv, T, fT, t, int1);


int2 = sub(i2, a, fa, J, fJ, v, fv, T, fT, t, 0):step:sub(i3, a, fa, J, fJ, v, fv, T, fT, t, 0);
[tS, tdS, td2S, td3S] = f(s_2,ds_2,d2s_2,d3s_2, a, fa, J, fJ, v, fv, T, fT, t, int2);
S = [S tS];
dS = [dS tdS];
d2S = [d2S td2S];
d3S = [d3S td3S];


int3 = sub(i3, a, fa, J, fJ, v, fv, T, fT, t, 0):step:sub(i4, a, fa, J, fJ, v, fv, T, fT, t, 0);
[tS, tdS, td2S, td3S] = f(s_3,ds_3,d2s_3,d3s_3, a, fa, J, fJ, v, fv, T, fT, t, int3);
S = [S tS];
dS = [dS tdS];
d2S = [d2S td2S];
d3S = [d3S td3S];


int4 = sub(i4, a, fa, J, fJ, v, fv, T, fT, t, 0):step:sub(i5, a, fa, J, fJ, v, fv, T, fT, t, 0);
[tS, tdS, td2S, td3S] = f(s_4,ds_4,d2s_4,d3s_4, a, fa, J, fJ, v, fv, T, fT, t, int4);
S = [S tS];
dS = [dS tdS];
d2S = [d2S td2S];
d3S = [d3S td3S];


int5 = sub(i5, a, fa, J, fJ, v, fv, T, fT, t, 0):step:sub(i6, a, fa, J, fJ, v, fv, T, fT, t, 0);
[tS, tdS, td2S, td3S] = f(s_5,ds_5,d2s_5,d3s_5, a, fa, J, fJ, v, fv, T, fT, t, int5);
S = [S tS];
dS = [dS tdS];
d2S = [d2S td2S];
d3S = [d3S td3S];


int6 = sub(i6, a, fa, J, fJ, v, fv, T, fT, t, 0):step:sub(i7, a, fa, J, fJ, v, fv, T, fT, t, 0);
[tS, tdS, td2S, td3S] = f(s_6,ds_6,d2s_6,d3s_6, a, fa, J, fJ, v, fv, T, fT, t, int6);
S = [S tS];
dS = [dS tdS];
d2S = [d2S td2S];
d3S = [d3S td3S];



int7 = sub(i7, a, fa, J, fJ, v, fv, T, fT, t, 0):step:fT;
[tS, tdS, td2S, td3S] = f(s_7,ds_7,d2s_7,d3s_7, a, fa, J, fJ, v, fv, T, fT, t, int7);
S = [S tS];
dS = [dS tdS];
d2S = [d2S td2S];
d3S = [d3S td3S];

% Конечный интервал
interval = [int1, int2, int3, int4, int5, int6, int7];

% Графики
figure
plot(interval,S)
grid on
title('S')
figure
plot(interval,dS)
grid on
title('dS')
figure
plot(interval,d2S)
grid on
title('d2S')
figure
plot(interval,d3S)
grid on
title('d3S')

% Функция подсчета функций на интервале 
function [S, dS, d2S, d3S] = f(s, ds, d2s, d3s, a, fa, J, fJ, v, fv, T, fT, t, ft)
S = sub(s, a, fa, J, fJ, v, fv, T, fT, t, ft);
dS =  sub(ds, a, fa, J, fJ, v, fv, T, fT, t, ft);
d2S = sub(d2s, a, fa, J, fJ, v, fv, T, fT, t, ft);
d3S = sub(d3s, a, fa, J, fJ, v, fv, T, fT, t, ft);
end

% Функция подстановка значений вместо символьных переменных
function res = sub(f, a, fa, J, fJ, v, fv, T, fT, t, ft)
res = double(subs(subs(subs(subs(subs(f,J,fJ),a,fa),v,fv),T, fT),t,ft));
end
