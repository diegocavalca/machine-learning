import os, re, requests, datetime, time, glob
from flask import Flask, request, Response, render_template
from PIL import Image, ImageEnhance
import PIL.ImageOps    
import numpy as np
import pandas as pd
import unidecode
import subprocess
import cv2
import pytesseract
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities
from selenium.webdriver.common.keys import Keys
from selenium.webdriver import FirefoxOptions
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By 

from libs import iteration
from libs import convert_to_text

from python_anticaptcha import AnticaptchaClient, NoCaptchaTaskProxylessTask, ImageToTextTask

import img2pdf

"""
Instalações:
    1)  pip install unidecode, pytesseract, selenium, python_anticaptcha, img2pdf
    2) https://www.vultr.com/docs/how-to-install-phantomjs-on-ubuntu-16-04
    3) bash install_geckodriver.sh
"""

#if os.environ.get("WERKZEUG_RUN_MAIN") == "true":
#    import face_recognition_api

def normalizaString(string):
    return unidecode.unidecode(str(string)).replace('.','').replace('/','').replace('-','')

app = Flask(__name__)

#dirFR = os.path.dirname(os.path.abspath(__file__)) + '/face_recognition'
#dirDataset = dirFR + '/dataset'
# Dados da API de captcha
api_key = 'ANTICAPTCHA_SERVICE_KEY'

cnae = re.compile('\d{2}.\d{2}-\d{1}-\d{2}')

service_args=['--ignore-ssl-errors=true', '--ssl-protocol=any', '--web-security=false']
dcap = dict(DesiredCapabilities.PHANTOMJS)
dcap["phantomjs.page.settings.userAgent"] = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.122 Safari/537.36")

# for CORS
@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,POST') # Put any other methods you need here
    return response

@app.route('/')
def index():
    return Response('Exemplo RPA - Certidoes Federais, Estaduais e Municipais')

# simular https: http://userpath.co/blog/a-simple-way-to-run-https-on-localhost/
def loadDriver(url, delayUpdate = 0, optDriver = 'firefox', screenW = 1366, screenH = 768, bgColor = 'white'):
    
    # Driver Selenium (Cache Website)
    if optDriver.lower() == 'firefox':

        opts = FirefoxOptions()
        opts.add_argument("--headless")
        #opts.add_argument(service_args)
        fp = webdriver.FirefoxProfile()
        #fp.accept_untrusted_certs = True
        fp.set_preference("browser.download.folderList",2)
        fp.set_preference("browser.download.dir", "/path_to_downloads_folder/")
        fp.set_preference("browser.helperApps.alwaysAsk.force", False)
        fp.set_preference("browser.helperApps.neverAsk.saveToDisk", "application/pdf,application/csv,application/excel,application/vnd.msexcel,application/vnd.ms-excel,text/anytext,text/comma-separated-values,text/csv,application/vnd.ms-excel,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/octet-stream")
        fp.set_preference("browser.helperApps.neverAsk.openFile","application/pdf,application/csv,application/excel,application/vnd.msexcel,application/vnd.ms-excel,text/anytext,text/comma-separated-values,text/csv,application/vnd.ms-excel,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/octet-stream")
        fp.set_preference("browser.download.manager.showWhenStarting", False)
        fp.set_preference("browser.download.manager.useWindow", False)
        fp.set_preference("browser.download.manager.focusWhenStarting", False)
        fp.set_preference("browser.download.manager.alertOnEXEOpen", False)
        fp.set_preference("browser.download.manager.showAlertOnComplete", False)
        fp.set_preference("browser.download.manager.closeWhenDone", True)
        fp.set_preference("pdfjs.disabled", True)
        fp.set_preference('browser.download.panel.shown', False)
        fp.set_preference('pdfjs.enabledCache.state', False)
        driver = webdriver.Firefox(firefox_options=opts, firefox_profile=fp)

    elif optDriver.lower() == 'chrome':

        # https://blog.softhints.com/ubuntu-16-04-server-install-headless-google-chrome/
        options = webdriver.ChromeOptions() 
        options.add_argument("download.default_directory=/path_to_downloads_folder/")
        options.add_argument("download.prompt_for_download=False")
        options.add_argument("download.directory_upgrade=True")
        options.add_argument("safebrowsing.enabled=True")
        options.add_argument('--ignore-certificate-errors')
        options.add_argument("--headless")
        options.add_argument("window-size="+str(screenW)+","+str(screenH)+"")
        options.add_argument("--no-sandbox")
        driver = webdriver.Chrome(chrome_options=options, executable_path='/usr/local/bin/chromedriver')

    else:
        driver = webdriver.PhantomJS(service_args=service_args)
    driver.set_window_size(screenW, screenH)
    driver.get(url)

    time.sleep( delayUpdate ) 

    return driver

# Resolver ReCaptcha
def solveRecaptcha(url, idForm, fields, idSubmit, delayUpdate):
    
    driver = loadDriver(url, 2)

    form = driver.find_element_by_id( idForm )
    #print(form.text)

    # Resolvendo ReCaptcha
    captchaPanel = form.find_element_by_class_name("g-recaptcha")
    siteKey = captchaPanel.get_attribute("data-sitekey")
    print('> ' + siteKey)

    client = AnticaptchaClient(api_key)
    session = requests.Session()
    task = NoCaptchaTaskProxylessTask(website_url=url,
                                      website_key=siteKey)
    job = client.createTask(task)
    job.join()
    tokenCaptcha = job.get_solution_response()
    print('> Token: ' + tokenCaptcha)

    driver.execute_script('document.getElementById("g-recaptcha-response").style.display="block"')
    captchaField = driver.find_element_by_id('g-recaptcha-response')
    captchaField.clear()
    captchaField.send_keys( tokenCaptcha )
    driver.execute_script('document.getElementById("g-recaptcha-response").style.display="none"')
    print('> ReCap. Response: '+ captchaField.get_attribute("value") )

    # Campo(s) de consulta(s) - Formulario
    for key, value in fields.items():
        field = driver.find_element_by_id( key )
        field.clear()
        field.send_keys( value )
    #print( driver.page_source )
    
    # Submeter form
    button = driver.find_element_by_id( idSubmit )
    button.click()
    time.sleep( delayUpdate ) 

    return driver#.

# Resolver ReCaptcha
def solveRecaptcha0(url, captchaPanel):
    
    # Resolvendo ReCaptcha
    siteKey = captchaPanel.get_attribute("data-sitekey")
    print('> ' + siteKey)

    client = AnticaptchaClient(api_key)
    session = requests.Session()
    task = NoCaptchaTaskProxylessTask(website_url=url,
                                      website_key=siteKey)
    job = client.createTask(task)
    job.join()
    tokenCaptcha = job.get_solution_response()
    print('> Token: ' + tokenCaptcha)

    return tokenCaptcha

# Resolver Image Captcha
def solveCaptcha(driver, captchaImg, captchaField, infoFields, btnSubmit, delayUpdate = 2):
    
    #driver = loadDriver(url, 2)

    #form = driver.find_element_by_id( idForm )
    #print(form.text)

    # Captcha Imagem
    imgUrl = captchaImg.get_attribute("src")

    # Capturar e arquivar temporariamente o Caaptcha
    tempFile = 'captcha/'+ str(datetime.datetime.now().timestamp()).replace('.', '_') + '.png'
    captcha = Image.open(requests.get(imgUrl, verify=False, stream=True).raw)#.convert('RGB')
    captcha.save(tempFile)
    captcha_fp = open(tempFile, 'rb')

    # Quebra do Captcha
    client = AnticaptchaClient(api_key)
    task = ImageToTextTask(captcha_fp)
    job = client.createTask(task)
    job.join()
    textCaptcha = job.get_captcha_text()

    # Apagar temporario
    os.remove(tempFile)

    print('Captcha >>> ' + textCaptcha)

    #captchaField = driver.find_element_by_id( idCaptchaField )
    captchaField.clear()
    captchaField.send_keys( textCaptcha )

    print('>>> Field Cap.: '+ captchaField.get_attribute("value") )

    # Campo(s) de consulta(s) - Formulario
    if len(infoFields.items())>0:
        for field, value in infoFields.items():
            #field = driver.find_element_by_id( key )
            field.clear()
            field.send_keys( value )

    btnSubmit.click()
    print('>>> Button: ' + btnSubmit.get_attribute("value") )

    time.sleep( delayUpdate ) 

    return driver#.page_source

# Resolver Image Captcha
def solveCaptcha0(captchaImg):
    
    # Captcha Imagem
    imgUrl = captchaImg.get_attribute("src")

    # Capturar e arquivar temporariamente o Caaptcha
    tempFile = 'captcha/'+ str(datetime.datetime.now().timestamp()).replace('.', '_') + '.png'
    captcha = Image.open(requests.get(imgUrl, verify=False, stream=True).raw)#.convert('RGB')
    captcha.save(tempFile)
    captcha_fp = open(tempFile, 'rb')

    # Quebra do Captcha
    client = AnticaptchaClient(api_key)
    task = ImageToTextTask(captcha_fp)
    job = client.createTask(task)
    job.join()
    textCaptcha = job.get_captcha_text()

    # Apagar temporario
    os.remove(tempFile)

    print('Captcha >>> ' + textCaptcha)

    return textCaptcha

# Resolver Dynamic Image Captcha
def solveDynamicCaptcha(driver, captchaImg, captchaW, captchaH):
    # # # Captcha Imagem (dinamic URL)
    # Capturar e arquivar temporariamente o Captcha
    tempFile = 'captcha/'+ str(datetime.datetime.now().timestamp()).replace('.', '_') + '.png'
    driver.save_screenshot( tempFile ) # Screenshot da tela
    # Localizacao da imagem na captura
    loc = captchaImg.location
    # Carregando screen e capturando captcha
    image = cv2.imread(tempFile)
    # Dimensoes do captcha
    captchaImg = image[loc['y']:loc['y']+captchaH, loc['x']:loc['x']+captchaW]
    cv2.imwrite(tempFile, captchaImg)
    captcha_fp = open(tempFile, 'rb')
    # Quebra do Captcha
    client = AnticaptchaClient(api_key)
    task = ImageToTextTask(captcha_fp)
    job = client.createTask(task)
    job.join()
    textCaptcha = job.get_captcha_text()
    # # # Captcha Imagem (dinamic URL)

    os.remove(tempFile)

    return textCaptcha

def salvarPDF(servico, campoConsulta, driver, areaCertidao, areaW, areaH, screenW = 1366, screenH = 768):
    # Salvar PDF 
    # 0) Definir arquivos
    agora = datetime.datetime.now().strftime("%d%m%Y.%H%M%S")
    arquivo = 'static/certidoes/' + servico + '-' + campoConsulta + '-' + str(agora) 
    screenshot = arquivo + '.png'
    pdf = arquivo+'.pdf'
    #print(arquivo)

    # 1) Screenshot da tela
    driver.execute_script('document.body.style.cssText = "background:white !important"')#.style.background = "white"')
    # JUCEV
    #driver.execute_script('document.getElementById( "DivCentroAutoAtendimento" ).style.backgroundColor = "white"')
    #screenW, screenH = pygame.display.get_surface().get_size()
    #screenW, screenH = (1366, 768)
    driver.set_window_size(screenW, screenH)
    driver.save_screenshot( screenshot ) 
    if areaCertidao and areaW > 0 and areaH > 0:
        loc = areaCertidao.location
        # Extrair area da certidao (dados)
        image = cv2.imread( screenshot )
        cropImg = image[loc['y']:loc['y']+areaH, loc['x']:loc['x']+areaW]
        cv2.imwrite( screenshot , cropImg)

    # 2) Img -> PDF
    with open(pdf,"wb") as certidao:
        certidao.write(img2pdf.convert( screenshot ))
    os.remove(arquivo + '.png')

    return request.url_root + pdf

@app.route('/cartao_cnpj', methods = ['GET', 'POST'])
def cartao_cnpj():
    
    #print(request)
    #print(request.form)
    #print(request.args)
    try:
        servico = 'CARTAO_CNPJ'
        status = False
        msg = ''
        data = {}

        try:

            # Parametros do formulario de busca - Form (ex.: {ID_INPUT: VALUE})
            params = {"cnpj": ""}

            # Tratando requisicao
            if request.method == 'POST':
                for k, v in params.items():
                    if request.form[ k ]:
                        params[ k ] = normalizaString(request.form[ k ])   
            elif request.method == 'GET':
                for k, v in params.items():
                    if request.args.get( k ):
                        params[ k ] = normalizaString(request.args.get( k ))  
            else:
                msg = 'Requisicao invalida para esta funcao!'

            if params['cnpj']:
                # # # Iniciar processamento da Requisicao
                urlForm = 'http://www.receita.fazenda.gov.br/PessoaJuridica/CNPJ/cnpjreva/Cnpjreva_Solicitacao2.asp'

                # Resolvendo Captcha / Submetendo formulario
                driver = solveRecaptcha(urlForm, "theForm", params, 'submit1', 3)

                try:
                    # Dados da consulta - Resultado
                    areaCertidao = driver.find_element_by_id('principal').find_elements_by_tag_name('table')[2]
                    #print(driver.page_source)
                    print(0)

                    # Salvar PDF 
                    certidao = salvarPDF(servico, params['cnpj'], driver, areaCertidao, 642, 675)
                    print(1)
                    print(certidao)

                    data['certidao'] = certidao
                    msg = 'Consulta realizada com sucesso'
                    status = True

                except Exception as e:
                    msg = 'Não foi possível concluir a consulta: ' + str(e)
                
                driver.quit()

            else:
                msg = 'Parametro obrigatorio ausente -> cnpj'

        except OSError as e:
            msg = 'Não foi possível concluir a consulta: ' + str(e)

        return pd.io.json.dumps({"status": status, "message": msg, "data": data})
        #return jsonify({"status": status, "message": msg, "data": data})

    except Exception as e:
        return pd.io.json.dumps({"status": False, "message": str(e)})
# # # # #
# def get_request_session(driver):
#     import requests
#     session = requests.Session()
#     for cookie in driver.get_cookies():
#         session.cookies.set(cookie['name'], cookie['value'])
#     return session
@app.route('/jucesp', methods = ['GET', 'POST'])
def jucesp():

    try:
        servico = 'JUCESP'
        data = {}
        status = False
        msg = ''
        # Dados de acessso sistema JUCESP        
        usuario = '69948194004'
        senha = 'N!nD0012345'

        try:

            # Parametros do formulario de busca - Form (ex.: {ID_INPUT: VALUE})
            params = {"nire": ""}

            # Tratando requisicao
            if request.method == 'POST':
                for k, v in params.items():
                    if request.form[ k ]:
                        params[ k ] = normalizaString(request.form[ k ])   
            elif request.method == 'GET':
                for k, v in params.items():
                    if request.args.get( k ):
                        params[ k ] = normalizaString(request.args.get( k ))  
            else:
                msg = 'Requisicao invalida para esta funcao!'

            if params['nire']:
                # # # Iniciar processamento da Requisicao
                # 35215909282
                driver = loadDriver( 'https://www.jucesponline.sp.gov.br/Pre_Visualiza.aspx?nire=' + params['nire'] )

                try: 

                    # Instanciar componentes e argumentos
                    captchaImg = driver.find_element_by_id("formBuscaAvancada").find_element_by_tag_name("img")
                    captchaField = driver.find_element_by_name('ctl00$cphContent$frmPreVisualiza$CaptchaControl1')
                    infoFields = {}
                    btnSubmit = driver.find_element_by_id('ctl00_cphContent_frmPreVisualiza_btEntrar')

                    # 1) Resolvendo Captcha / Submetendo formulario
                    driver = solveCaptcha(driver, captchaImg, captchaField, infoFields, btnSubmit, 3)
                    time.sleep(3)
                    driver.save_screenshot('screenshot1.png')
                    #print(driver.page_source)

                    # 2) Solicitando Ficha Simplificada
                    btnFicha = driver.find_element_by_id('ctl00_cphContent_frmPreVisualiza_btnEmitir')
                    btnFicha.click()
                    time.sleep(5)
                    driver.switch_to.window(driver.window_handles[-1]) # Acessar nova aba
                    driver.save_screenshot('screenshot2.png')
                    #print(driver.page_source)

                    # 3) Area restrita
                    # Instanciar componentes e argumentos
                    captchaImg = driver.find_element_by_xpath("//img[@width='180']")
                    captchaField = driver.find_element_by_name('ctl00$cphContent$CaptchaControl1')
                    infoFields = {'ctl00_cphContent_txtEmail': usuario, 'ctl00_cphContent_txtSenha': senha}
                    btnSubmit = driver.find_element_by_id('ctl00_cphContent_btEntrar')
                    #driver = solveCaptcha(driver, captchaImg, captchaField, infoFields, btnSubmit, 2)
                    
                    #.#.#.#.#.#
                    imgUrl = captchaImg.get_attribute("src")
                    print('> ' + imgUrl)

                    # Capturar e arquivar temporariamente o Caaptcha
                    tempFile = 'captcha/'+ str(datetime.datetime.now().timestamp()).replace('.', '_') + '.png'
                    captcha = Image.open(requests.get(imgUrl, verify=False, stream=True).raw)#.convert('RGB')
                    captcha.save(tempFile)
                    captcha_fp = open(tempFile, 'rb')

                    # Quebra do Captcha
                    client = AnticaptchaClient(api_key)
                    task = ImageToTextTask(captcha_fp)
                    job = client.createTask(task)
                    job.join()
                    textCaptcha = job.get_captcha_text()

                    # Apagar temporario
                    os.remove(tempFile)

                    print('Captcha >>> ' + textCaptcha)

                    #captchaField = driver.find_element_by_id( idCaptchaField )
                    captchaField.clear()
                    captchaField.send_keys( textCaptcha )

                    print('>>> Field Cap.: '+ captchaField.get_attribute("value") )

                    # Campo(s) de consulta(s) - Formulario
                    if len(infoFields.items())>0:
                        for key, value in infoFields.items():
                            field = driver.find_element_by_id( key )
                            field.clear()
                            field.send_keys( value )

                    # Remover arquivo (download automatico)
                    arqCertidao = 'VisualizaTicket.aspx' 
                    if os.path.exists(arqCertidao):
                        os.remove(arqCertidao)

                    # Submeter formulario
                    # wait = WebDriverWait(driver, 5)
                    # button = wait.until(
                    #             EC.element_to_be_clickable(
                    #                 (By.XPATH, '//input[@type="submit" and @id="ctl00_cphContent_btEntrar"]')))
                    # driver.execute_script("arguments[0].scrollIntoView()", button)
                    # button.click()
                    captchaField.send_keys(Keys.RETURN)
                    print('>>> Button: ' + btnSubmit.get_attribute("value") )
                    time.sleep( 5 )
                    print('> Current URL: ' + driver.current_url)
                    driver.save_screenshot('screenshot3.png')
                    #.#.#.#.#.#

                    # 4.1) Definir arquivos
                    agora = datetime.datetime.now().strftime("%d%m%Y.%H%M%S")
                    arquivo = 'static/certidoes/'+ servico + '-' + params['nire'] +'-'+ str(agora)
                    pdf = arquivo+'.pdf'
                    print('>>> PDF URL: '+ request.url_root + pdf )
                    # 4.2) Renomear e mover arquivo baixado
                    os.rename(arqCertidao, pdf)
                    print('Fim')

                    data['certidao'] = request.url_root + pdf 
                    msg = 'Consulta realizada com sucesso'
                    status = True

                except Exception as e:
                    msg = 'Não foi possível concluir a consulta: ' + str(e)

                driver.quit()
                
            else:
                msg = 'Parametro obrigatorio ausente -> nire'

        except OSError as e:
            msg = 'Não foi possível concluir a consulta: ' + str(e)

        return pd.io.json.dumps({"status": status, "message": msg, "data": data})

    except Exception as e:
        return pd.io.json.dumps({"status": False, "message": str(e)})
# # # # #

@app.route('/juceb', methods = ['GET', 'POST'])
def juceb():
# Exemplo:
# URL/juceb?cnpj=03736962000100&nire=

    try:
        servico = 'JUCEB'
        status = False
        msg = ''
        data = {}

        try:
            # Parametros do formulario de busca
            params = {"nire": "", "cnpj": ""}

            # Tratando requisicao
            if request.method == 'POST':
                for k, v in params.items():
                    if request.form[ k ]:
                        params[ k ] = normalizaString(request.form[ k ])   
            elif request.method == 'GET':
                for k, v in params.items():
                    if request.args.get( k ):
                        params[ k ] = normalizaString(request.args.get( k ))  
            else:
                msg = 'Requisicao invalida para esta funcao!'

            if params['nire'] or params['cnpj']:
                # # # Iniciar processamento da Requisicao

                # URL alvo
                urlForm = 'http://www.certidaoonline.juceb.ba.gov.br/certidao/publico/consultanireempresa'

                # Driver Selenium (Cache Website)
                driver = loadDriver(urlForm, 0)#, screenH = 935, screenW = 768)
                driver.execute_script('document.body.style.background = "white"')

                # Carregar formulario
                form = driver.find_element_by_id("formListarEmpresas")

                ### SEM CAPTCHA ###

                # Preencher campos do formulario
                # NIRE:
                field = form.find_element_by_name('pessoaJuridicaVO.nrNire')
                field.clear()
                field.send_keys( params['nire'] )
                # CNPJ:
                field = form.find_element_by_name('pessoaJuridicaVO.nrCgc')
                field.clear()
                field.send_keys( params['cnpj'] )

                # Submeter consulta
                button = form.find_elements_by_tag_name('a')[0]
                button.click()
                time.sleep(2.5) 

                try:
                    # Dados da consulta - Resultado
                    #areaCertidao = driver.find_element_by_id('principal').find_elements_by_tag_name('table')[2]
                    #print(driver.page_source)

                    # Salvar PDF 
                    wSize = 900
                    hSize = driver.find_element_by_tag_name('body').size['height']
                    certidao = salvarPDF(servico, params['cnpj'], driver, [], 0, 0, wSize, hSize)
                    
                    data['certidao'] = certidao
                    msg = 'Consulta realizada com sucesso'
                    status = True
                except Exception as e:
                    msg = 'Não foi possível concluir a consulta: ' + str(e)

                # Encerra webdriver
                driver.quit()

            else:
                msg = 'Parametro obrigatorio ausente -> nire ou cnpj'

        except OSError as e:
            msg = 'Não foi possível concluir a consulta: ' + str(e)

        return pd.io.json.dumps({"status": status, "message": msg, "data": data})

    except Exception as e:
        return pd.io.json.dumps({"status": False, "message": str(e)})
# # # # #

@app.route('/cnd_federal', methods = ['GET', 'POST'])
def cnd_federal():
# Exemplo:
# URL/cnd_federal?cnpj=03736962000100
# - - -
# OBSERVAÇÃO: O captcha é carreado através de um serviço prórpio, ou seja, é necessário
# uma estratégia que capture a imagem do captcha no instante de acesso e
# faça a quebra do captcha a partir desta imagem.
    try:
        servico = 'CND_FEDERAL'
        status = False
        msg = ''
        data = {}

        try:
            # Parametros do formulario de busca
            params = {"cnpj": ""}

            # Tratando requisicao
            if request.method == 'POST':
                for k, v in params.items():
                    if request.form[ k ]:
                        params[ k ] = normalizaString(request.form[ k ])   
            elif request.method == 'GET':
                for k, v in params.items():
                    if request.args.get( k ):
                        params[ k ] = normalizaString(request.args.get( k ))  
            else:
                msg = 'Requisicao invalida para esta funcao!'
            #print(0)
            if params['cnpj']:
                # # # Iniciar processamento da Requisicao

                # URL alvo
                urlForm = 'https://servicos.receita.fazenda.gov.br/Servicos/certidao/CndConjuntaInter/InformaNICertidao.asp?Tipo=1'
                
                # # Driver Selenium (Cache Website)
                # driver = webdriver.PhantomJS(service_args=service_args)
                # #screenW, screenH = pygame.display.get_surface().get_size()
                # screenW, screenH = (1366, 768)
                # driver.set_window_size(screenW, screenH)
                # driver.get(urlForm)
                driver = loadDriver(urlForm, 0, 'phantomjs')
                
                # Carregar formulario
                form = driver.find_element_by_name("CertidaoNegativa")

                ### CAPTCHA ###
                # Captcha Imagem (dinamic URL)
                # Capturar e arquivar temporariamente o Caaptcha
                tempFile = 'captcha/'+ str(datetime.datetime.now().timestamp()).replace('.', '_') + '.png'
                driver.save_screenshot( tempFile ) # Screenshot da tela
                img = form.find_element_by_id("imgCaptchaSerpro") # Localizacao da imagem na captura
                loc = img.location
                # Carregando screen e capturando captcha
                image = cv2.imread(tempFile)
                w = 180 # Dimensoes do captcha
                h = 50
                captchaImg = image[loc['y']:loc['y']+h, loc['x']:loc['x']+w]
                cv2.imwrite(tempFile, captchaImg)
                captcha_fp = open(tempFile, 'rb')

                # Quebra do Captcha
                client = AnticaptchaClient(api_key)
                task = ImageToTextTask(captcha_fp)
                job = client.createTask(task)
                job.join()
                textCaptcha = job.get_captcha_text()
                print(textCaptcha)

                # Apagar temporario
                os.remove(tempFile)
                # ### CAPTCHA ###

                # Preencher campos do formulario
                # CAPTCHA:
                #print(0)
                field = form.find_element_by_id('txtTexto_captcha_serpro_gov_br')
                field.clear()
                field.send_keys( textCaptcha )
                #print('>>> ' + field.get_attribute('value')) 
                # CNPJ:
                #print(1)
                field = form.find_element_by_name('NI')
                field.clear()
                field.send_keys( params['cnpj'] )
                #print('>>> ' + field.get_attribute('value')) 

                #print(driver.page_source)

                # Submeter consulta
                #print(2)
                #driver.save_screenshot('screenshot.png')
                #print(driver.page_source)
                button = form.find_element_by_id('submit1')
                button.click()
                time.sleep(5) 
                
                # msg = driver.page_source
                # print(msg)

                try:
                    # Tentar obter através 2ª tela
                    #driver.set_window_size(800, driver.get_window_size()['height'])
                    button = driver.find_elements_by_tag_name('a')[-2]
                    print(button.get_attribute('innerHTML'))
                    button.click()
                    time.sleep(5) 

                    certidao = salvarPDF(servico, params['cnpj'], driver, [], 0, 0)
                    data['certidao'] = certidao
                    msg = 'Consulta realizada com sucesso'
                    status = True
                except Exception as e:
                    try:
                        # Resultado
                        #areaCertidao = driver.find_element_by_id('PRINCIPAL')
                        #driver.set_window_size(800, 200)#driver.get_window_size()['height'])
                        certidao = salvarPDF(servico, params['cnpj'], driver, [], 0, 0)
                        data['certidao'] = certidao
                        msg = 'Consulta realizada com sucesso'
                        status = True
                    except Exception as e:
                        #print(5)
                        msg = 'Não foi possível concluir a consulta: ' + str(e)

                # Encerra webdriver
                driver.quit()

            else:
                msg = 'Parametro obrigatorio ausente -> cnpj'

        except OSError as e:
            msg = 'Não foi possível concluir a consulta: ' + str(e)

        return pd.io.json.dumps({"status": status, "message": msg, "data": data})

    except Exception as e:
        return pd.io.json.dumps({"status": False, "message": str(e)})
# # # # #

@app.route('/cnd_sp', methods = ['GET', 'POST'])
def cnd_sp():
# Exemplo:
# URL/cnd_sp?documento=9999&tipo=CPF_CNPJ
# - - -
    try:
        servico = 'CND_SP'
        status = False
        msg = ''
        data = {}

        try:
            # Parametros do formulario de busca
            params = {"documento": "", "tipo": ""}

            # Tratando requisicao
            if request.method == 'POST':
                for k, v in params.items():
                    if request.form[ k ]:
                        params[ k ] = normalizaString(request.form[ k ])   
            elif request.method == 'GET':
                for k, v in params.items():
                    if request.args.get( k ):
                        params[ k ] = normalizaString(request.args.get( k ))  
            else:
                msg = 'Requisicao invalida para esta funcao!'
            #print(0)
            if params['documento'] and params['tipo']:
                # # # Iniciar processamento da Requisicao

                # Webdriver
                driver = loadDriver( 'https://www10.fazenda.sp.gov.br/CertidaoNegativaDeb/Pages/EmissaoCertidaoNegativa.aspx' )

                try:

                    # 1) Resolvendo Captcha
                    textCaptcha = solveCaptcha0( driver.find_element_by_id("MainContent_imgcapcha") )
                    captchaField = driver.find_element_by_name('ctl00$MainContent$txtConfirmaCaptcha')
                    captchaField.clear()
                    captchaField.send_keys( textCaptcha )
                    print('>>> Field Cap.: '+ captchaField.get_attribute("value") )
                    ### OBSRVCO: Quebra do captcha HARD

                    # 2) Preenchendo formulario de consulta
                    field = driver.find_element_by_name('ctl00$MainContent$txtDocumento')
                    field.clear()
                    field.send_keys( params["documento"] )
                    #
                    field = driver.find_elements_by_name('ctl00$MainContent$grupoDocumento')
                    if params['tipo'].lower() == 'cpf':
                        field[0].click()
                    else:
                        field[-1].click()

                    # Submetendo consulta
                    btnSubmit = driver.find_element_by_id('MainContent_btnPesquisar')
                    btnSubmit.click()
                    time.sleep(2)         

                    print(driver.page_source)           

                    data['certidao'] = 'QUEBRA DO CAPTCHA INVIAVEL! (ESTUDAR ALTERNATIVA)'
                    msg = 'Consulta realizada com sucesso'
                    status = True

                except Exception as e:
                    msg = 'Não foi possível concluir a consulta: ' + str(e)

                # Encerra webdriver
                driver.quit()

            else:
                msg = 'Parametro obrigatorio ausente -> documento e/ou tipo'

        except OSError as e:
            msg = 'Não foi possível concluir a consulta: ' + str(e)

        return pd.io.json.dumps({"status": status, "message": msg, "data": data})

    except Exception as e:
        return pd.io.json.dumps({"status": False, "message": str(e)})
# # # # #

@app.route('/sefaz_ce', methods = ['GET', 'POST'])
def sefaz_ce():
# Exemplo:
# URL/sefaz_ce?documento=07797967000195&tipo=CPF_CNPJ_CGF
# - - -
    try:
        servico = 'sefaz_ce'.upper()
        status = False
        msg = ''
        data = {}

        try:
            # Parametros do formulario de busca
            params = {"documento": "", "tipo": ""}

            # Tratando requisicao
            if request.method == 'POST':
                for k, v in params.items():
                    if request.form[ k ]:
                        params[ k ] = normalizaString(request.form[ k ])   
            elif request.method == 'GET':
                for k, v in params.items():
                    if request.args.get( k ):
                        params[ k ] = normalizaString(request.args.get( k ))  
            else:
                msg = 'Requisicao invalida para esta funcao!'
            #print(0)
            if params['documento'] and params['tipo']:
                # # # Iniciar processamento da Requisicao

                # Webdriver
                driver = loadDriver( 'https://www.sefaz.ce.gov.br/content/aplicacao/internet/servicos_online/certidao/emissao/default.asp?ca=AP6389858?8??88;3A7A7B3A5B7B8%3E8@857A@97B8?4?5B7B8%3E8@8582857@7%3E7A8;8?' )

                try:

                    # 1) Resolvendo Captcha
                    # SEM CAPTCHA

                    # 2) Preenchendo formulario de consulta
                    field = driver.find_element_by_name('txtCodigo')
                    field.clear()
                    field.send_keys( params["documento"] )
                    #
                    field = driver.find_elements_by_name('radTipo')
                    if params['tipo'].lower() == 'cpf':
                        field[0].click()
                    elif params['tipo'].lower() == 'cnpj':
                        field[1].click()
                    else:
                        field[-1].click()

                    # 3) Submetendo consulta
                    btnSubmit = driver.find_element_by_name('B1')
                    btnSubmit.click()
                    time.sleep(2)      
                    driver.switch_to.window(driver.window_handles[-1]) # Acessar nova aba   

                    # 4) Salvar PDF 
                    # 4.1) Definir arquivos
                    agora = datetime.datetime.now().strftime("%d%m%Y.%H%M%S")
                    arquivo = 'static/certidoes/'+ servico + '-' + params['documento'] +'-'+ str(agora)
                    screenshot = arquivo+'.png'
                    pdf = arquivo+'.pdf'
                    # 4.3) Screenshot da tela
                    driver.save_screenshot( screenshot ) 
                    # 4.4) Area de interesse (documento)
                    # loc = dados.location
                    # image = cv2.imread(screenshot)
                    # w = 784 # Dimensoes do captcha
                    # h = 519
                    # cropImg = image[loc['y']:loc['y']+h, loc['x']+280:loc['x']+280+w]
                    # cv2.imwrite(screenshot, cropImg)
                    # 4.4) Img -> PDF
                    with open(pdf,"wb") as certidao:
                        certidao.write(img2pdf.convert( screenshot ))
                    os.remove(screenshot)

                    data['certidao'] = request.url_root + pdf 
                    msg = 'Consulta realizada com sucesso'
                    status = True

                except Exception as e:
                    msg = 'Não foi possível concluir a consulta: ' + str(e)

                # Encerra webdriver
                driver.quit()

            else:
                msg = 'Parametro obrigatorio ausente -> documento, tipo e/ou modelo'

        except OSError as e:
            msg = 'Não foi possível concluir a consulta: ' + str(e)

        return pd.io.json.dumps({"status": status, "message": msg, "data": data})

    except Exception as e:
        return pd.io.json.dumps({"status": False, "message": str(e)})
# # # # #

@app.route('/sefaz_mt', methods = ['GET', 'POST'])
def sefaz_mt():
# Exemplo:
# URL/sefaz_mt?documento=03819150000110&tipo=IE_CPF_CNPJ&modelo=NUMERO_MODELO_CERTIDAO
# - - -
    try:
        servico = 'sefaz_mt'.upper()
        status = False
        msg = ''
        data = {}

        try:
            # Parametros do formulario de busca
            params = {"documento": "", "tipo": "", "modelo": ""}

            # Tratando requisicao
            if request.method == 'POST':
                for k, v in params.items():
                    if request.form[ k ]:
                        params[ k ] = normalizaString(request.form[ k ])   
            elif request.method == 'GET':
                for k, v in params.items():
                    if request.args.get( k ):
                        params[ k ] = normalizaString(request.args.get( k ))  
            else:
                msg = 'Requisicao invalida para esta funcao!'
            #print(0)
            if params['documento'] and params['tipo'] and params['modelo']:
                # # # Iniciar processamento da Requisicao

                # Webdriver
                driver = loadDriver( 'https://www.sefaz.mt.gov.br/cnd/certidao/servlet/ServletRotd?origem=60' )

                try:

                    # 1) Resolvendo Captcha
                    # # # Captcha Imagem (dinamic URL)
                    # Capturar e arquivar temporariamente o Captcha
                    tempFile = 'captcha/'+ str(datetime.datetime.now().timestamp()).replace('.', '_') + '.png'
                    driver.save_screenshot( tempFile ) # Screenshot da tela
                    img = driver.find_element_by_xpath('//img[@src="/cnd/certidao/geradorcaracteres"]') # Localizacao da imagem na captura
                    loc = img.location
                    # Carregando screen e capturando captcha
                    image = cv2.imread(tempFile)
                    w = 200 # Dimensoes do captcha
                    h = 65
                    captchaImg = image[loc['y']:loc['y']+h, loc['x']:loc['x']+w]
                    cv2.imwrite(tempFile, captchaImg)
                    captcha_fp = open(tempFile, 'rb')
                    # Quebra do Captcha
                    client = AnticaptchaClient(api_key)
                    task = ImageToTextTask(captcha_fp)
                    job = client.createTask(task)
                    job.join()
                    textCaptcha = job.get_captcha_text()
                    # # # Captcha Imagem (dinamic URL)
                    captchaField = driver.find_element_by_name('caracteres')
                    captchaField.clear()
                    captchaField.send_keys( textCaptcha )
                    os.remove(tempFile)
                    print('>>> Field Cap.: '+ captchaField.get_attribute("value") )

                    # 2) Preenchendo formulario de consulta
                    field = driver.find_elements_by_name('tipoDoct')
                    if params['tipo'].lower() == 'ie':
                        field[0].click()
                    elif params['tipo'].lower() == 'cpf':
                        field[1].click()
                    else:
                        field[-1].click()
                    #
                    field = driver.find_element_by_name('numrDoct')
                    field.clear()
                    field.send_keys( params["documento"] )

                    # 3) Submetendo consulta
                    btnSubmit = driver.find_element_by_name('btnOk')
                    btnSubmit.click()
                    time.sleep(2)      
                    #driver.switch_to.window(driver.window_handles[-1]) # Acessar nova aba  

                    # Escolher modelo de certidao / Submeter emissao
                    field = driver.find_elements_by_name('ModeloCertidao')
                    field[int(params['modelo'])].click()
                    driver.find_element_by_name('botaoSubmit').click()
                    time.sleep(20) 

                    #print(driver.page_source) 

                    # 4) Salvar PDF 
                    # 4.1) Definir arquivos
                    agora = datetime.datetime.now().strftime("%d%m%Y.%H%M%S")
                    arquivo = 'static/certidoes/'+ servico + '-' + params['documento'] +'-'+ str(agora)
                    screenshot = arquivo+'.png'
                    pdf = arquivo+'.pdf'
                    # 4.3) Screenshot da tela
                    driver.save_screenshot( screenshot ) 
                    # 4.4) Area de interesse (documento)
                    # loc = dados.location
                    # image = cv2.imread(screenshot)
                    # w = 784 # Dimensoes do captcha
                    # h = 519
                    # cropImg = image[loc['y']:loc['y']+h, loc['x']+280:loc['x']+280+w]
                    # cv2.imwrite(screenshot, cropImg)
                    # 4.4) Img -> PDF
                    with open(pdf,"wb") as certidao:
                        certidao.write(img2pdf.convert( screenshot ))
                    os.remove(screenshot)

                    data['certidao'] = request.url_root + pdf 
                    msg = 'Consulta realizada com sucesso'
                    status = True

                except Exception as e:
                    print('>>> ERROR: '+ str(e))
                    msg = 'Não foi possível concluir a consulta: ' + str(e)

                # Encerra webdriver
                driver.quit()

            else:
                msg = 'Parametro obrigatorio ausente -> documento e/ou tipo'

        except OSError as e:
            msg = 'Não foi possível concluir a consulta: ' + str(e)

        return pd.io.json.dumps({"status": status, "message": msg, "data": data})

    except Exception as e:
        return pd.io.json.dumps({"status": False, "message": str(e)})
# # # # #

@app.route('/sefaz_pr', methods = ['GET', 'POST'])
def sefaz_pr():
# Exemplo:
# URL/sefaz_pr?documento=20129563000191&tipo=CPF_CNPJ
# - - -
    try:
        servico = 'sefaz_pr'.upper()
        status = False
        msg = ''
        data = {}

        try:
            # Parametros do formulario de busca
            params = {"documento": "", "tipo": ""}

            # Tratando requisicao
            if request.method == 'POST':
                for k, v in params.items():
                    if request.form[ k ]:
                        params[ k ] = normalizaString(request.form[ k ])   
            elif request.method == 'GET':
                for k, v in params.items():
                    if request.args.get( k ):
                        params[ k ] = normalizaString(request.args.get( k ))  
            else:
                msg = 'Requisicao invalida para esta funcao!'
            #print(0)
            if params['documento'] and params['tipo']:
                # # # Iniciar processamento da Requisicao

                # Webdriver 
                driver = loadDriver( 'http://www.cdw.fazenda.pr.gov.br/cdw/emissao/certidaoAutomatica', 2)#, 0, 'phantomjs' )

                try:

                    # 1) Resolvendo Captcha
                    # # # Captcha Imagem (dinamic URL)
                    # Capturar e arquivar temporariamente o Captcha
                    tempFile = 'captcha/'+ str(datetime.datetime.now().timestamp()).replace('.', '_') + '.png'
                    driver.save_screenshot( tempFile ) # Screenshot da tela
                    img = driver.find_element_by_id('imgCaptcha') # Localizacao da imagem na captura
                    loc = img.location
                    # Carregando screen e capturando captcha
                    image = cv2.imread(tempFile)
                    w = 150 # Dimensoes do captcha
                    h = 40
                    captchaImg = image[loc['y']:loc['y']+h, loc['x']:loc['x']+w]
                    cv2.imwrite(tempFile, captchaImg)
                    captcha_fp = open(tempFile, 'rb')
                    # Quebra do Captcha
                    client = AnticaptchaClient(api_key)
                    task = ImageToTextTask(captcha_fp)
                    job = client.createTask(task)
                    job.join()
                    textCaptcha = job.get_captcha_text()
                    # # # Captcha Imagem (dinamic URL)
                    captchaField = driver.find_element_by_id('EmissaoCaptcha')
                    captchaField.clear()
                    captchaField.send_keys( textCaptcha )
                    os.remove(tempFile)
                    print('>>> Field Cap.: '+ captchaField.get_attribute("value") )

                    # 2) Preenchendo formulario de consulta
                    if params['tipo'].lower() == 'cpf':
                        field = driver.find_element_by_id('EmissaoCpf')
                    else:
                        field = driver.find_element_by_id('EmissaoCnpj')
                    field.clear()
                    field.send_keys( params["documento"] )

                    # 3) Submetendo consulta
                    btnSubmit = driver.find_element_by_id('emitir')
                    btnSubmit.click()
                    time.sleep(5)     
                    #print(btnSubmit) 
                    #driver.switch_to.window(driver.window_handles[-1]) # Acessar nova aba  

                    try:
                        aviso = driver.find_element_by_class_name('msg_aviso')
                        msg = 'Erro: '+ aviso.text
                    except:
                        # Verificar se baixou o arquivo da certidao
                        certidoes = glob.glob('Certidao_Negativa_de_Debitos_*.pdf')
                        print(certidoes)
                        if len(certidoes)>0:
                            agora = datetime.datetime.now().strftime("%d%m%Y.%H%M%S")
                            pdf = 'static/certidoes/'+ servico + '-' + params['documento'] +'-'+ str(agora) + '.pdf'
                            os.rename(certidoes[0], pdf)
                            
                            #os.rename(arqCertidao, pdf)
                            data['certidao'] = request.url_root + pdf 
                            msg = 'Consulta realizada com sucesso'
                            status = True 
                        else:
                            msg = 'Não foi possível baixar a certidão.'                      

                except Exception as e:
                    print('>>> ERROR: '+ str(e))
                    msg = 'Não foi possível concluir a consulta: ' + str(e)

                # Encerra webdriver
                driver.quit()

            else:
                msg = 'Parametro obrigatorio ausente -> documento e/ou tipo'

        except OSError as e:
            msg = 'Não foi possível concluir a consulta: ' + str(e)

        return pd.io.json.dumps({"status": status, "message": msg, "data": data})

    except Exception as e:
        return pd.io.json.dumps({"status": False, "message": str(e)})
# # # # #

@app.route('/sefaz_rs', methods = ['GET', 'POST'])
def sefaz_rs():
# Exemplo:
# URL/sefaz_rs?documento=20129563000191&tipo=CPF_CNPJ
# - - -
    try:
        servico = 'sefaz_rs'.upper()
        status = False
        msg = ''
        data = {}

        try:
            # Parametros do formulario de busca
            params = {"documento": "", "tipo": ""}

            # Tratando requisicao
            if request.method == 'POST':
                for k, v in params.items():
                    if request.form[ k ]:
                        params[ k ] = normalizaString(request.form[ k ])   
            elif request.method == 'GET':
                for k, v in params.items():
                    if request.args.get( k ):
                        params[ k ] = normalizaString(request.args.get( k ))  
            else:
                msg = 'Requisicao invalida para esta funcao!'
            #print(0)
            if params['documento'] and params['tipo']:
                # # # Iniciar processamento da Requisicao

                # Webdriver
                urlForm = 'https://www.sefaz.rs.gov.br/sat/CertidaoSitFiscalSolic.aspx'
                driver = loadDriver( urlForm, 2 )#, 'chrome')#'phantomjs' )

                try:

                    # 1) Resolvendo Captcha
                    # # # ReCaptcha
                    tokenCaptcha = solveRecaptcha0( urlForm, driver.find_element_by_class_name("g-recaptcha") )
                    captchaField = driver.find_element_by_id('g-recaptcha-response') # Fz Captcha visivel
                    driver.execute_script('document.getElementById("g-recaptcha-response").style.display="block"')
                    #print(captchaField)
                    captchaField.clear()
                    captchaField.send_keys( tokenCaptcha )
                    print('>> Recaptcha Response: '+ captchaField.get_attribute("value") )
                    driver.execute_script('document.getElementById("g-recaptcha-response").style.display="none"')

                    # 2) Preenchendo formulario de consulta
                    if params['tipo'].lower() == 'cpf':
                        field = driver.find_element_by_name('campoCpf')
                    else:
                        field = driver.find_element_by_name('campoCnpj')
                    field.clear()
                    field.send_keys( params["documento"] )

                    # 2.2) Remover arquivo (download automatico)
                    arqCertidao = 'certidao.pdf'
                    if os.path.exists(arqCertidao):
                        os.remove(arqCertidao)

                    # Submeter formulario
                    # 3) Submetendo consulta
                    btnSubmit = driver.find_element_by_xpath('//input[@value="Enviar"]')
                    btnSubmit.click()
                    time.sleep(3)      
                    #driver.switch_to.window(driver.window_handles[-1]) # Acessar nova aba  

                    # 4) Salvar PDF 
                    # 4.1) Definir arquivos
                    agora = datetime.datetime.now().strftime("%d%m%Y.%H%M%S")
                    arquivo = 'static/certidoes/'+ servico + '-' + params['documento'] +'-'+ str(agora)
                    pdf = arquivo+'.pdf'
                    # 4.2) Renomear e mover arquivo baixado
                    os.rename(arqCertidao, pdf)

                    data['certidao'] = request.url_root + pdf 
                    msg = 'Consulta realizada com sucesso'
                    status = True                       

                except Exception as e:
                    print('>>> ERROR: '+ str(e))
                    msg = 'Não foi possível concluir a consulta: ' + str(e)

                # Encerra webdriver
                driver.quit()

            else:
                msg = 'Parametro obrigatorio ausente -> documento e/ou tipo'

        except OSError as e:
            msg = 'Não foi possível concluir a consulta: ' + str(e)

        return pd.io.json.dumps({"status": status, "message": msg, "data": data})

    except Exception as e:
        return pd.io.json.dumps({"status": False, "message": str(e)})
# # # # #

@app.route('/sefaz_ma', methods = ['GET', 'POST'])
def sefaz_ma():
# Exemplo:
# URL/sefaz_ma?documento=05657704000155&tipo=IE_CPFCNPJ
# - - -
    try:
        servico = 'sefaz_ma'.upper()
        status = False
        msg = ''
        data = {}

        try:
            # Parametros do formulario de busca
            params = {"documento": "", "tipo": ""}

            # Tratando requisicao
            if request.method == 'POST':
                for k, v in params.items():
                    if request.form[ k ]:
                        params[ k ] = normalizaString(request.form[ k ])   
            elif request.method == 'GET':
                for k, v in params.items():
                    if request.args.get( k ):
                        params[ k ] = normalizaString(request.args.get( k ))  
            else:
                msg = 'Requisicao invalida para esta funcao!'
            #print(0)
            if params['documento'] and params['tipo']:
                # # # Iniciar processamento da Requisicao

                # Webdriver
                urlForm = 'https://sistemas.sefaz.ma.gov.br/certidoes/jsp/emissaoCertidaoNegativa/emissaoCertidaoNegativa.jsf'
                driver = loadDriver( urlForm, 2 )#, 'chrome')#'phantomjs' )

                try:

                    # 0) Tratando tipo do documento (refresh selecting)
                    field = driver.find_elements_by_name('form1:tipoEmissao')
                    if params['tipo'].lower() == 'cpfcnpj':
                        field[-1].click()
                        time.sleep(3)                    

                    # 1) Resolvendo Captcha
                    textCaptcha = solveDynamicCaptcha(driver, driver.find_element_by_id("form1:captcha"), 100,25)
                    captchaField = driver.find_element_by_name('form1:j_id20')
                    captchaField.clear()
                    captchaField.send_keys( textCaptcha )
                    print('>>> Field Cap.: '+ captchaField.get_attribute("value") )

                    # 2) Preenchendo formulario de consulta
                    if params['tipo'].lower() == 'cpfcnpj':
                        field = driver.find_element_by_name('form1:cpfCnpj')
                    else:
                        field = driver.find_element_by_name('form1:inscricaoEstadual')
                    field.clear()
                    field.send_keys( params["documento"] )

                    # 3) Submetendo consulta
                    btnSubmit = driver.find_element_by_id('form1:j_id28')
                    btnSubmit.click()
                    time.sleep(5)     
                    #print(btnSubmit) 
                    driver.switch_to.window(driver.window_handles[-1]) # Acessar nova aba  

                    # Verificar se houve erro
                    try:
                        aviso = driver.find_element_by_class_name('msg_aviso')
                        msg = 'Erro: '+ aviso.text
                    except:
                        # Verificar se baixou o arquivo da certidao
                        certidoes = glob.glob('emissaoCertidaoNegativa*')
                        print(certidoes)
                        if len(certidoes)>0:
                            agora = datetime.datetime.now().strftime("%d%m%Y.%H%M%S")
                            pdf = 'static/certidoes/'+ servico + '-' + params['documento'] +'-'+ str(agora) + '.pdf'
                            os.rename(certidoes[0], pdf)

                            data['certidao'] = request.url_root + pdf 
                            msg = 'Consulta realizada com sucesso'
                            status = True 
                        else:
                            msg = 'Não foi possível baixar a certidão: o serviço está indisponível.'                      

                except Exception as e:
                    print('>>> ERROR: '+ str(e))
                    msg = 'Não foi possível concluir a consulta: ' + str(e)

                # Encerra webdriver
                driver.quit()

            else:
                msg = 'Parametro obrigatorio ausente -> documento e/ou tipo'

        except OSError as e:
            msg = 'Não foi possível concluir a consulta: ' + str(e)

        return pd.io.json.dumps({"status": status, "message": msg, "data": data})

    except Exception as e:
        return pd.io.json.dumps({"status": False, "message": str(e)})
# # # # #

@app.route('/cnd_municipal_sp', methods = ['GET', 'POST'])
def cnd_municipal_sp():
# Exemplo:
# URL/cnd_municipal_sp?documento=00102300267&certidao=2
# - - -
    try:
        servico = 'cnd_municipal_sp'.upper()
        status = False
        msg = ''
        data = {}

        try:
            # Parametros do formulario de busca
            params = {"documento": "", "certidao": ""}

            # Tratando requisicao
            if request.method == 'POST':
                for k, v in params.items():
                    if request.form[ k ]:
                        params[ k ] = normalizaString(request.form[ k ])   
            elif request.method == 'GET':
                for k, v in params.items():
                    if request.args.get( k ):
                        params[ k ] = normalizaString(request.args.get( k ))  
            else:
                msg = 'Requisicao invalida para esta funcao!'
            #print(0)
            if params['documento'] and params['certidao']:
                # # # Iniciar processamento da Requisicao

                # Webdriver
                urlForm = 'https://duc.prefeitura.sp.gov.br/certidoes/forms_anonimo/frmConsultaEmissaoCertificado.aspx'
                driver = loadDriver( urlForm, 2 )#, 'chrome')#'phantomjs' )

                try:

                    # 0) Tratando tipo de certidao (refresh selecting)
                    driver.find_element_by_xpath("//select[@name='ctl00$ConteudoPrincipal$ddlTipoCertidao']/option[@value='"+str(params['certidao'])+"']").click()
                    time.sleep(2)     

                    # 1) Resolvendo Captcha
                    textCaptcha = solveDynamicCaptcha(driver, driver.find_element_by_id("ctl00_ConteudoPrincipal_imgCaptcha"), 180,50)
                    #textCaptcha = solveCaptcha0( driver.find_element_by_id("ctl00_ConteudoPrincipal_imgCaptcha") )
                    captchaField = driver.find_element_by_id('ctl00_ConteudoPrincipal_txtValorCaptcha')
                    captchaField.clear()
                    captchaField.send_keys( textCaptcha )
                    print('>>> Field Cap.: '+ captchaField.get_attribute("value") )

                    # 2) Preenchendo formulario de consulta
                    if int(params['certidao']) == 2: 
                        # Certidão Tributária de IPTU
                        field = driver.find_element_by_id('ctl00_ConteudoPrincipal_txtSQL')                    
                    else: 
                        # Certidão Tributária Mobiliária /  Certidão Unificada de Tributos Municipais 
                        field = driver.find_element_by_id('ctl00_ConteudoPrincipal_txtCNPJ')
                    field.clear()
                    field.click() # Posicionando cursor no inicio do campo (Mascara)
                    #field.send_keys( params["documento"] ) 
                    for digito in params["documento"]:
                        field.send_keys(Keys.END, digito)
                        time.sleep(0.1)

                    # 3) Submetendo consulta
                    btnSubmit = driver.find_element_by_id('ctl00_ConteudoPrincipal_btnEmitir')
                    print( '>>> Button: ' + btnSubmit.get_attribute("value") )
                    btnSubmit.click()
                    time.sleep(5)     

                    # 4) Verificar se baixou o arquivo da certidao
                    certidoes = glob.glob('Relatorio_Certidao_*')
                    print(certidoes)
                    if len(certidoes)>0:
                        agora = datetime.datetime.now().strftime("%d%m%Y.%H%M%S")
                        pdf = 'static/certidoes/'+ servico + '-' + params['documento'] +'-'+ str(agora) + '.pdf'
                        os.rename(certidoes[0], pdf)

                        data['certidao'] = request.url_root + pdf 
                        msg = 'Consulta realizada com sucesso'
                        status = True 
                    else:
                        msg = 'Não foi possível baixar a certidão: o serviço está indisponível.'                      

                except Exception as e:
                    print('>>> ERROR: '+ str(e))
                    msg = 'Não foi possível concluir a consulta: ' + str(e)

                # Encerra webdriver
                driver.quit()

            else:
                msg = 'Parametro obrigatorio ausente -> documento e/ou certidao'

        except OSError as e:
            msg = 'Não foi possível concluir a consulta: ' + str(e)

        return pd.io.json.dumps({"status": status, "message": msg, "data": data})

    except Exception as e:
        return pd.io.json.dumps({"status": False, "message": str(e)})
# # # # #

@app.route('/prefeitura_rj', methods = ['GET', 'POST'])
def prefeitura_rj():
# Exemplo:
# URL/prefeitura_rj?inscricao=05097908&email=email@email.com
# - - -
    try:
        servico = 'prefeitura_rj'.upper()
        status = False
        msg = ''
        data = {}

        try:
            # Parametros do formulario de busca
            params = {"inscricao": "", "email": ""}

            # Tratando requisicao
            if request.method == 'POST':
                for k, v in params.items():
                    if request.form[ k ]:
                        params[ k ] = request.form[ k ]#normalizaString(request.form[ k ])   
            elif request.method == 'GET':
                for k, v in params.items():
                    if request.args.get( k ):
                        params[ k ] = request.args.get( k )#normalizaString(request.args.get( k ))  
            else:
                msg = 'Requisicao invalida para esta funcao!'
            #print(0)
            if params['inscricao'] and params['email']:
                # # # Iniciar processamento da Requisicao

                # Webdriver
                urlForm = 'http://www2.rio.rj.gov.br/smf/forms/pesquisa.asp'
                driver = loadDriver( urlForm, 2 )#, 'chrome')#'phantomjs' )

                try:

                    # 1) Resolvendo Captcha
                    textCaptcha = solveDynamicCaptcha(driver, driver.find_element_by_class_name("TDCentro"), 112,36)
                    captchaField = driver.find_element_by_name('texto_imagem')
                    captchaField.clear()
                    captchaField.send_keys( textCaptcha )
                    print('>>> Field Cap.: '+ captchaField.get_attribute("value") )

                    # 2) Preenchendo formulario de consulta
                    field = driver.find_element_by_id('numinscricaoiss')                    
                    field.clear()
                    field.send_keys( params["inscricao"] ) 

                    print(params["email"])
                    field = driver.find_element_by_id('email')                    
                    field.clear()
                    field.send_keys( params["email"] ) 

                    # 3) Submetendo consulta - Pt. 1
                    #driver.save_screenshot('screenshot1.png')
                    btnSubmit = driver.find_elements_by_class_name('btinput')[1]
                    print( '>>> Button: ' + btnSubmit.get_attribute("value") )
                    btnSubmit.click()
                    time.sleep(8)     

                    # 3.2) Submetendo consulta - Pt. 2
                    #driver.save_screenshot('screenshot2.png')
                    btnSubmit = driver.find_elements_by_class_name('btinput')[1]
                    print( '>>> Button: ' + btnSubmit.get_attribute("value") )
                    btnSubmit.click()
                    time.sleep(2)   

                    # 3.3) Submetendo consulta - Pt. 3
                    #driver.save_screenshot('screenshot3.png')
                    btnSubmit = driver.find_elements_by_class_name('btinput')[1]
                    print( '>>> Button: ' + btnSubmit.get_attribute("value") )
                    btnSubmit.click()
                    time.sleep(3)   
                    driver.switch_to.window(driver.window_handles[-1]) # Acessar nova aba  

                    # 4) Salvar PDF
                    agora = datetime.datetime.now().strftime("%d%m%Y.%H%M%S")
                    arquivo = 'static/certidoes/'+ servico + '-' + params["inscricao"] +'-'+ str(agora)
                    screenshot = arquivo+'.png'
                    pdf = arquivo+'.pdf'
                    
                    driver.save_screenshot( screenshot ) 
                    with open(pdf,"wb") as certidao:
                        certidao.write(img2pdf.convert( screenshot ))
                    os.remove(screenshot)
                    
                    data['certidao'] = request.url_root + pdf 
                    msg = 'Consulta realizada com sucesso'
                    status = True                      

                except Exception as e:
                    print('>>> ERROR: '+ str(e))
                    msg = 'Não foi possível concluir a consulta: ' + str(e)

                # Encerra webdriver
                driver.quit()

            else:
                msg = 'Parametro obrigatorio ausente -> inscricao e/ou email'

        except OSError as e:
            msg = 'Não foi possível concluir a consulta: ' + str(e)

        return pd.io.json.dumps({"status": status, "message": msg, "data": data})

    except Exception as e:
        return pd.io.json.dumps({"status": False, "message": str(e)})
# # # # #

# https://github.com/pdfminer/pdfminer.six 

if __name__ == '__main__':
    portNumber = 5002

    # without SSL
    #app.run(debug=True, host='0.0.0.0', port=portNumber)

    # with SSL
    app.run(debug=True, host='0.0.0.0', port=portNumber, ssl_context='adhoc')