function [fitness, consPotLiquido, consPotBruto, consValor, ...
            vrTotal, consMaximo, consMedio, consPico, PAR ] ...
        = custo(planejamento, dispositivos, tarifa)
 
    % OUTPUT:
    % custoTOtal = custoEnergia + PAR
    % consPotencia = vetor de consumo em potencia, por hora
    % consValor = vetor de consumo em valor monetario, por hora
    % PAR = balanco entre consumo maximo e consumo medio (potencia)

    % Variaveis base
    global pico;
    limiteTempo = 24; %size(planejamento, 2); % Limite da janela de tempo (ex.: 24 H)
    totalDisps = size(dispositivos,1);    % Total de disps contemplados
    %%%%% Calculando os custos %%%%%
    
    % Geracao de energia
    eGer = zeros(1, 24);
    
    % Gerando perfil de consumo (Bruto/Liquido)
    consPotBruto = reshape(planejamento,[limiteTempo,totalDisps])'; % Bruto
    consPotLiquido = sum(consPotBruto) - eGer; % Liquido

    % Valor consumido por hora
    consValor = consPotLiquido .* tarifa(1:24);%bsxfun(@times, consEnergyLiq, bsxfun(@times,ones(numLoads,H),tariff));
    
    % Funcao de custo FINAL (Ponderar VR_TOTAL e PAR)
    vrTotal = sum(consValor);       % Considerando apenas o valor total consumido
    consMaximo = max(consPotLiquido);  % Consumo medio durante o horizonte de planejamento
    consMedio  = mean(consPotLiquido); % Consumo medio durante o horizonte de planejamento
    PAR     = consMaximo/consMedio; 
    consPico = sum(consPotLiquido(pico));
    w1 = 1;%.8;
    w2 = 1;%.2;
    %fitness = w1*vrTotal + w2*PAR;  % Considerando o PAR (SPAVIERI, 2016)
    fitness = w1*vrTotal + w2*consPico;
    %custoTotal = vrTotal;
    %custoTotal = max(consPotLiquido)/mean(consPotLiquido);
end

% function [planejamento] = perfil(agendamento, dispositivos)
%   
%   %A = length(agendamento); % quantidade de dispositivos (ciclos) contemplados
%   
%   totalDisps = size(dispositivos,1);
%   
%   planejamento = zeros(totalDisps, 24); % Matriz de planejamento (perfil de consumo)
%   
%   %c = 1; % Controle de ciclos do agendamento
%   
%   for d = 1:totalDisps;
%     
%     % Dados do dispositivo
%     dispositivo = dispositivos(d, :);              
%         
%     % Duracao (de cada ciclo, em horas)
%     duracao  = dispositivo.ConsPlanejado/(dispositivo.PotMaxima/1000);   
%     
%     % Duracao (de cada ciclo, em minutos)
%     %duracao_m  = duracao_h * 60;      
%                
%     % Inicio do funcionamento do aparelho
%     inicio = agendamento(d);  
%     inicio_int = floor(inicio);
%     % Fim do funcionamento
%     %disp(duracao_h);
%     fim = inicio + duracao; 
%     fim_int = floor(fim);
%     
%     % Periodo em standBy
%     planejamento(d, dispositivo.Inicio:dispositivo.Fim) = dispositivo.PotMinima/1000;
% 
%     % Definir perfil de consumo (kWh) do dispositivo 
%     % em cada hora da janela de funcionamento estabelecida
%     % 'inicio' até 'fim' (fim = inicio + duracao_h)
%     for horario = inicio_int:fim_int;
%         % Ajustar a tempo de funcionamento no instante 'horario'
%         if(inicio_int == fim_int); % Caso o funcionamento esteja dentro de janela de 1 hora
%             func = duracao;
%         else
%             % Caso seja a hora de INICIO DO AGENDAMENTO, validar
%             % se o tempo de funcionamento contempla 60 minutos (ex.:
%             % aparelho agendado a parti das 6:30, com duracao de 45
%             % minutos irá caber apenas 30 minutos na hora inicial)
%             if(horario == inicio_int); 
%                 func = (inicio_int + 1) - inicio;
%             % Caso seja a hora FINAL DA JANELA DE AGENDAMENTO, validar 
%             % quantos minutos ainda restam para alocar (ex.: inicio de
%             % agend. as 6:30 com aparelho de duração de 45 minutos. Na
%             % hora 7, o aparelho vai funcionar 15 minutos)
%             elseif(horario == fim_int);
%                 func = fim - fim_int; 
%             else
%                 func = 1; % Senao, Hora cheia de funcionamento
%             end;
%         end;
%         % Verificar se eh consumido no instante
%         if(func > 0);
% 
%             % Ajuste de horario de inicio do ciclo(limite de 24h)
%             h = horario; 
%             if(h > 24);
%                 h = h - 24;
%             end;
% 
%             planejamento(d, floor(h)) = func;
% 
%             %disp(strcat(num2str(horario),' = ', num2str(func)));
%         end;
%     end;
%         
%         %c = c + 1; % Atualizando controle de ciclos
% 
%     %end;
%     
%   end;
%     
% end

function [eGer] = geracaoEnergia(h)
  enersud = zeros(1, 25);%[150,150,150,150,150,160,190,200,230,260,325,360,380,450,410,380,360,325,230,190,180,175,150,150];%rep(0, 24)
  kyocera = zeros(1, 25);%[0,0,0,0,10,110,300,470,530,600,650,650,600,670,460,300,110,10,0,0,0,0,0,0];%#rep(0, 24)
  veiculo = zeros(1, 25);
  eGer = (enersud(h) + kyocera(h) + veiculo(h))/1000;
end