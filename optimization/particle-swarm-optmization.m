clear;clc;

N=4;
n_iter = 100;
X = zeros(n_iter,N); % Posicao
V = X; % Velocidade
f = V; % Custos

% Inicial
X(1,:) = [-1.5 0.0 0.5 1.25];
V(1,:) = [0 0 0 0];

% Fitness
for i = 1:N;
    f(1,i) = -X(1,i)^2 + 2*X(1,i)+11;
end;

r1 = 0.3294;
r2 = 0.9542;

% PBest / Gbest - INICIAL
[Pbest,idxPbest] = max(f);
Pbest = X(idxPbest(1),:);
[Gbest,idxGbest] = max(Pbest);

for i=2:n_iter;
    
    %r1 and r2 are random numbers...
    
    for j=1:N;
        % Velocidades 
        V(i,j) = V(i-1,j) + r1*(Pbest(j) - X(i-1,j)) + r2*(Gbest - X(i-1,j));
        
        % Nova posicao (voo da particula 'i')      
        X(i,j) = X(i-1,j) + V(i,j);
        
        % Fitnesss...
        f(i,j) = -X(i,j)^2 + 2*X(i,j)+11;
    end;
    
    % PBest / Gbest - Iterativo
    [Pbest,idxPbest] = max(f);
    Pbest = X(idxPbest(1),:);
    [Gbest,idxGbest] = max(Pbest);    
    
    % Verificar convergencia ...
    convergence = max(f);
    for i=2:N;        
        % Verificar se possui valores proximos...
        diff = convergence(i) - convergence(i-1);
        if ( diff > 0.2 || diff < 0.2 ); break; end;
        
        % Se atingiu a ultima posicao, convergiu
        if (i==4) break; end;
    end;
    
end;

% Resultados...
[Pbest,idxPbest] = max(f);
[Gbest,idxGbest] = max(Pbest);  % Maior valor da funcao
% Melhor X
Xbest = X(idxPbest(1),:); 

% Plotando...
fig=figure; 
hax=axes; 

% Linha...
x=-2:0.1:2;
y= -x.^2 + 2*x + 11;
plot(x,y);

% Estrela...
hold on;
plot(Xbest(idxGbest), Gbest, '*');

% Linha do pc
%line([Xbest(idxGbest) Xbest(idxGbest)],get(hax,'YLim'),'Color',[1 0 0])