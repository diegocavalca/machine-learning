% Encontrar o máximo da função f(x)= - x^2+2*x+11
% -2 <= x <=2
clear
clc
% numero de abelhas empregadas = 4
% numero de abelhas assistentes = 4
% numero de fontes de alimentos = 4
N = 4;
numIter = 10;
X = zeros(1,N);
f = X;
V = X;
limite=3; % uma fonte de alimento que não pode ser melhorada por tantas tentativas "limite"
contadorMelhora = zeros(1,N); % Validar fontes abandonadas

hist = zeros(numIter,2); % Historico de iteracoes e resultados

% posição/valor inicial das fontes de alimento
X(1,:) = [-1.5 0.0 0.5 1.25];
V(1,:) = [0 0 0 0];

% Fitness inicial
f = -X(1,:).^2 + 2*X(1,:) + 11;

iter = 1;
while iter <= numIter;

    % Abelhas empregadas...
    for i=1:N;
    
        % Novo valor da fonte de alimento (solucao)...
        k = randi(N);
        while k==i;
          k = randi(N);  
        end;
        phi =  unifrnd(-1,1);
        V(i) = X(i) + phi * ( X(i) - X(k) );
        
        % Reavalia Fitnesss...
        novoValor = -V(i)^2 + 2*V(i) + 11;
        
        % Verificar novo fitness (maximizar)
        if novoValor>f(i);
          X(i) = V(i);
          f(i) = novoValor;
          contadorMelhora(i) = 0;
        else
          contadorMelhora(i) = contadorMelhora(i) + 1;
        end;
        
    end;
    
    % Probabilidades associadas a cada valor...
    P = V(:) / sum(V);
    
    %% Abelhas assistentes...
    for m=1:N;
    
        % Roleta (selecionar solucao i com base em P...
        r=rand;
        C=cumsum(P);
        i=find(r<=C,1,'first');
                
        % Novo valor da fonte de alimento (solucao)...
        k = randi(N);
        while k==i;
          k = randi(N);  
        end;
        phi =  unifrnd(-1,1);
        V(i) = X(i) + phi * ( X(i) - X(k) );
        
        % Reavalia Fitnesss...
        novoValor = -V(i)^2 + 2*V(i) + 11;
        
        % Verificar novo fitness (maximizar)
        if novoValor>f(i);
          X(i) = V(i);
          f(i) = novoValor;
          contadorMelhora(i) = 0;
        else
          contadorMelhora(i) = contadorMelhora(i) + 1;
        end;
        
    end;
    
    % Abelhas batedoras...
    for i=1:N
      % Verifica fontes abandonadas e troca por novas...
      if contadorMelhora(i)>=limite
          X(i) = unifrnd(1, N);
          f(i) = -X(i).^2 + 2*X(i) + 11;
          contadorMelhora(i)=0;
      end;
    end;
    
    % Verificar solucoes
    [v,idx] = max(f);
    hist(iter,:) = [v X(idx)];
    
    % Resultado iterativo..
    disp(sprintf('Iter: %d | Max-Func: %d, Max-X: %d ',iter,v,X(idx)));
    
    iter = iter + 1;
end;

% Resultado final (Maximo valor da funcao no historico)
[vMax,idxMax] = max(hist(:,1));
maxFuncao = hist(idxMax,:);

% Plotando funcao...
fig=figure; 
hax=axes; 

% Linha...
x=-2:0.01:2;
y= -x.^2 + 2*x + 11;
plot(x,y);

% Plotando historico (valores da funcao / X)...
figureHistory = figure();
plot(hist(:,1),'b','LineWidth',2);
title('Historico de iteracoes');
xlabel('Iteracao');
ylabel('Func');

figureHistory = figure();
plot(hist(:,2),'b','LineWidth',2);
title('Historico de iteracoes');
xlabel('Iteracao');
ylabel('X');
