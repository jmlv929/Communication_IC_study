%% matrix inversion 
syms fx x mat ;

A = sym('A%d%d', [2 4]);


%%
syms x y
ezmesh(x*exp(-x^2-y^2),[-2.5,2.5],40)
colormap([0 0 1])

%%
syms t
x = t*sin(5*t);
y = t*cos(5*t);
ezplot(x, y)

%%
syms x y
z = x^2 + y^2;
subplot(2, 2, 1); ezsurf(sin(z/100))
subplot(2, 2, 2); ezsurf(sin(z/50))
subplot(2, 2, 3); ezsurf(sin(z/20))
subplot(2, 2, 4); ezsurf(sin(z/10))

%%
syms x y
ezplot(exp(x)*sin(20*x) - y, [0, 3, -20, 20])
hold on
p1 = ezplot(exp(x) - y, [0, 3, -20, 20]);
set(p1,'Color','red', 'LineStyle', '--', 'LineWidth', 2)
p2 = ezplot(-exp(x) - y, [0, 3, -20, 20]);
set(p2,'Color','red', 'LineStyle', '--', 'LineWidth', 2)
title('exp(x)sin(20x)')
hold off
%%
syms a;
A = [1 a; -a 1];
X = pinv(A)

%%
syms a b z;
n=10;
for i=1:n
    A(i,i)=a;
    
end

A = [a;b];
X = pinv(A)

%%
