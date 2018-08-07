function [planejamento] = perfil(dispositivos, agendamento)
  
  % Quantidade de ciclos contemplados
  A = length(agendamento); 
  
  planejamento = zeros(A, 24); % Matriz de planejamento (perfil de consumo)
  
  c = 1; % Controle de ciclos do agendamento
  
  totalDisp = size(dispositivos,1);
  
  for d = 1:totalDisp;
    
    dispositivo = dispositivos(d, :);             % Dados do dispositivo
    %potencia_w = dispositivo{2};                  % Potencia (em Wats)
    %potencia_k = dispositivo{2}/1000; % Potencia (em KiloWats)
    duracao_m  = dispositivo{3};      % Duracao (de cada ciclo, em minutos)
    duracao_h  = duracao_m/60;        % Duracao (de cada ciclo, em horas)
    ciclos     = dispositivo{4};      % Ciclos
    
    for ciclo = (c:(c+ciclos-1));
      
        % Inicio do ciclo 'c' do aparelho 'd'
        inicio = agendamento(c);  
        inicio_int = floor(inicio);
        % Fim do ciclo
        %disp(duracao_h);
        fim = inicio + duracao_h; 
        fim_int = floor(fim);
        
        for horario = inicio_int:fim_int;
            % Ajustar a tempo de funcionamento no instante 'horario'
            if(inicio_int == fim_int); % Caso o funcionamento esteja dentro de janela de 1 hora
                func = duracao_h;
            else
                % Caso seja a hora de INICIO DO AGENDAMENTO, validar
                % se o tempo de funcionamento contempla 60 minutos (ex.:
                % aparelho agendado a parti das 6:30, com duracao de 45
                % minutos irá caber apenas 30 minutos na hora inicial)
                if(horario == inicio_int); 
                    func = (inicio_int + 1) - inicio;
                % Caso seja a hora FINAL DA JANELA DE AGENDAMENTO, validar 
                % quantos minutos ainda restam para alocar (ex.: inicio de
                % agend. as 6:30 com aparelho de duração de 45 minutos. Na
                % hora 7, o aparelho vai funcionar 15 minutos)
                elseif(horario == fim_int);
                    func = fim - fim_int; 
                else
                    func = 1; % Senao, Hora cheia de funcionamento
                end;
            end;
            % Verificar se eh consumido no instante
            if(func > 0);
                
                % Ajuste de horario de inicio do ciclo(limite de 24h)
                h = horario; 
                if(h > 24);
                    h = h - 24;
                end;
                
                planejamento(c, floor(h)) = func;
                
                %disp(strcat(num2str(horario),' = ', num2str(func)));
            end;
        end
        
        c = c + 1; % Atualizando controle de ciclos
        
%       dur_aux = 0;
%       for horario = floor(inicio):floor(inicio)+(ceil(duracao_h)-1);
%           
%         % Ajuste de horario de inicio do ciclo(limite de 24h)
%         h = horario; 
%         if(h > 24);
%             h = h - 24;
%         end;
%         
%         if(duracao_h > 1);
%           % Verificar se eh o ultimo ciclo e esta fracionado
%           if( (floor(duracao_h) == dur_aux) && (rem(duracao_h, 1) > 0) ); 
%             dur = duracao_h - dur_aux;
%           else
%             dur = 1;
%           end;
%         else
%             dur = duracao_h;
%         end;
%         dur_aux = dur_aux + 1;
%         
%         planejamento(c, floor(h)) = dur;
%         
%         %vrConsumo = (potencia_k * dur) * tarifa[h]
%         %cDiario = cDiario + vrConsumo      
%         %print(paste(ciclo, ' = ', h))
%       end;

    end;
    
  end;
    
end