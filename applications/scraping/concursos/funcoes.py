import requests
from bs4 import BeautifulSoup

import pandas as pd
pd.set_option('display.max_colwidth', -1) # Nao 'truncar' string pelo tamanho da coluna

from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import smtplib, time

import unidecode

import warnings
warnings.filterwarnings("ignore")

def limpar_string(string):
    return string.replace('\n','').replace('\t','').replace('\r','')

def tratar_string(string):
    #return string.encode("ascii", "xmlcharrefreplace")
    return unidecode.unidecode(string) # Remover spec. chars

def oportunidades_ifsp(url, keywords = []):
    
    keywords = [k.lower() for k in keywords] # normalizando keywords (lower())
    total_keywords = len(keywords)
    
    # 1. Scrapping
    conteudo = requests.get(url, verify=False)
    soup = BeautifulSoup(conteudo.text, 'html.parser', from_encoding="utf-8")
    
    # 2. Coletando elementos-alvo
    alvos = []
    alvos +=  soup.find_all( class_="view-novos-concursos" )
    alvos += soup.find_all( class_="view-inscrices-abertas" )
    #alvos += soup.find_all( class_="view-concluidos" )

    # 3. Extraindo dados
    dados = []
    for elemento in alvos:
        registros = elemento.find_all("a")
        for r in registros:
            # 3.1. Filtro de keywords (c/) Normalizacao conteudo do elemento (lower) )
            if total_keywords == 0 or any(k in str(r).lower() for k in keywords):
                dados.append({
                    "origem" : "ifsp",
                    "titulo" : tratar_string(r.text),
                    "url" : "https://concursopublico.ifsp.edu.br" + r['href'],
                    "local": ""
                })
    return dados

def oportunidades_pci(url, keywords = []):
    
    keywords = [k.lower() for k in keywords] # normalizando keywords (lower())
    total_keywords = len(keywords)
    
    # 1. Scrapping
    conteudo = requests.get(url, verify=False)
    soup = BeautifulSoup(conteudo.text, 'html.parser', from_encoding="utf-8")
    
    # 2. Coletando elementos-alvo
    alvos = []
    alvos +=  soup.find_all( class_="ca" )
    
    # 3. Extraindo dados
    dados = []
    for elemento in alvos:
        registros = elemento.find_all("a")
        for r in registros:
            # 3.1. Validacao:
            #   - Filtro de keywords (c/) Normalizacao conteudo do elemento (lower) )
            #   - Sem duplicacao de url/links
            if total_keywords == 0 or any(k in str(r).lower() for k in keywords) and not any(d['url'] == r['href'] for d in dados):
                dados.append({
                    "origem" : "PCI",
                    "titulo" : tratar_string(r.text),
                    "url" : r['href'],
                    "local": ""
                })
    return dados

def oportunidades_senac(url, keywords = []):
    
    keywords = [k.lower() for k in keywords] # normalizando keywords (lower())
    total_keywords = len(keywords)
    
    # 1. Scrapping
    conteudo = requests.get(url, verify=False)
    soup = BeautifulSoup(conteudo.text, 'html.parser', from_encoding="utf-8")
    
    # 2. Coletando elementos-alvo
    alvos = []
    alvos +=  soup.find_all( class_="box bgGray")
    #print(alvos)
    
    # 3. Extraindo dados
    dados = []
    for elemento in alvos:
        #print(elemento)
        registros = [elemento.find(id="titVaga")]
        local = elemento.find_all(class_="v1")[1].text.replace('Local','')
        #print(registros)
        for r in registros:
            # 3.1. Validacao:
            #   - Filtro de keywords (c/) Normalizacao conteudo do elemento (lower) )
            if total_keywords == 0 or any(k in str(local).lower() for k in keywords):
                dados.append({
                    "origem" : "SENAC",
                    "titulo" : tratar_string(r.text),
                    "url" : 'http://www.sp.senac.br/recru/portal/_display.jsp',
                    "local": limpar_string(local)                    
                })
    return dados

def enviar_email(email, dataset):
    # Enviando email
    # create message object instance
    msg = MIMEMultipart()

    message = "Ol&aacute; Diego.<br><br>Seguem oportunidades encontradas:<br><br>" + dataset.to_html() + "<br><br>Boa sorte!!! ;)"

    # setup the parameters of the message
    password = email["password"] #"5xR2W4ZYmqfMWg5"
    msg['From'] = email["from"] #"robot@diegocavalca.com"
    msg['To'] =  email["to"] #"diegoluizcavalca@gmail.com"
    msg['Subject'] = "Oportunidades - " + time.strftime("%d/%m/%Y")

    # add in the message body
    msg.attach(MIMEText(message, 'html'))

    #create server
    server = smtplib.SMTP( email["smtp"] )#'mail.diegocavalca.com: 587')

    server.starttls()

    # Login Credentials for sending the mail
    server.login(msg['From'], password)

    # send the message via the server.
    server.sendmail(msg['From'], msg['To'], msg.as_string())

    server.quit()

    #print( "Email enviado com sucesso p/ %s!" % (msg['To']) )
    return True