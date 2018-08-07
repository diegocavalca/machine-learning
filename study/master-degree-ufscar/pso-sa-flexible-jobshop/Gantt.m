function Gantt (schedule, scheduleOpsLabels, makespan, mSize)

  m = mSize;
  gantt = schedule;
  gantt_op = scheduleOpsLabels;
  
  V = (1:m);
  slots = gantt;

  for i = length(slots(1,:)):-1:2
      for j = 1:1:length(slots(:,1))
          if slots(j,i) > 0
             slots(j,i) = slots(j,i)-slots(j,i-1); 
          end
      end
  end

  figure;
  h = barh(V,slots,'stacked','LineStyle',':');
  set(h, 'FaceColor', [1,1,1]);
  set(h, 'EdgeColor', [0,0,0]);
  title('Grafico de Gantt');
  xlabel('Makespan');
  ylabel('Maquinas');
  set(gca, 'YDir', 'reverse');
  set(gca, 'YTick', 1:1:length(V));


  for i = 1:1:length(gantt(1,:))
      if mod(i,2) ~= 0
          set(h(i),'FaceColor',[0.8 0.8 0.8]); 
      end
  end

  for i=1:length(gantt_op(:,1))
      length_op = sum(~cellfun(@isempty,gantt_op(i,:)));
      for j=1:length_op        
          indice = (((gantt(i,(j-1)*2+1)+gantt(i,(j-1)*2+2))/2)-0.4);        
          text(indice,i,gantt_op(i,j))
      end
  end

end