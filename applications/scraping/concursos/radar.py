import funcoes
import sys
import pandas as pd

def main(args):
    #print(args)

    # Coleta de oportunidades
    print("Iniciando coletade oportunidades...\n")
    concursos = []
    print("Verificando IFSP... ", end = "")
    concursos += funcoes.oportunidades_ifsp('https://concursopublico.ifsp.edu.br/', keywords = ['docentes'])
    print("Ok!\nVerificando PCI Concursos... ", end = "")
    concursos += funcoes.oportunidades_pci('https://www.pciconcursos.com.br/professores/', keywords = ['bauru', 'são carlos', 'fatec'])
    print("Ok!\nVerificando Senac... ", end = "")
    concursos += funcoes.oportunidades_senac('http://www.sp.senac.br/recru/portal/_display.jsp', keywords = ['bauru'])
    print("Ok!")
    
    # Dic -> Df
    dataset = pd.DataFrame(concursos)

    print("\nEnviando email para "+ args[3] +"... ", end = "")
    funcoes.enviar_email({"from" : args[0],
                          "password" : args[1],
                          "smtp" : args[2],
                          "to" : args[3]}, 
                         dataset)
    print("Ok!")

if __name__ == "__main__":
    main(sys.argv[1:])