function [ janela ] = janelaAgendamento( dispositivo )

    if( (dispositivo.Inicio>0) && (dispositivo.Fim>0) ); % Caso janela fechada
        % Forcar funcionamento nos limites estabelecidos p/ aparelho
        % Ex.: Limites 13 as 18h, cons.Planejado (duracao) = 2.5h: 
        % Maximos: Inicio = 13h, Fim = (18 - ceil(2.5)) = 15h
        inicio = dispositivo.Inicio;
        duracao = dispositivo.ConsPlanejado/(dispositivo.PotMaxima/1000);
        fim = dispositivo.Fim - ceil( duracao );
        % Verificar se a duracao (ConsPlanejado) vai tomar todo limite
        % Ex.: Limites 8h e 16h, consPlanejado (dur.) = 8h
        % Nesse caso, a janela eh fechada nos limites estabelecidos, assim o 
        % dispositivo nao eh agendavel
        if (fim == 0);
            janela = inicio; % nao agendavel
        else
            if(inicio <= fim);
                janela = inicio:fim; % agendavel
            else
                janela = inicio:dispositivo.Fim; % agendavel (VERIFICAR!!! aparelho 64)
            end;
        end;
    else % janela aberta
        janela = 1:24; 
    end;


end

