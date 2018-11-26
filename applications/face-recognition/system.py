# coding=utf-8
"""Performs face detection in realtime.

Based on code from https://github.com/shanren7/real_time_face_recognition
"""
# MIT License
#
# Copyright (c) 2017 François Gervais
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
import argparse
import sys, os, time
wdir =  os.path.dirname(__file__) + "/../src"
sys.path.append(wdir)

# Bibliotecas de processamento de images / paralelizacao
import cv2, multiprocessing

# Importar pipeline de deteccao
from library import pipeline
# Recursos adicionais: configuracoes e utilitario de visao computacional.
from library import dlc, cv_utils 

from library import integration_sqlite as integration

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

def camera_proccessing(camera_name, camera_source):    
   # Inicializar lib de reconhecimento facial
    recognition = pipeline.Recognition()

    # Instanciar camera
    if str(camera_source).isnumeric(): # Caso USB
        camera_source = int(camera_source)
    cap = cv2.VideoCapture(camera_source)

    # Ajustando FPS
    # Intervalo de frames para executar reconhecimento facial (sincronia com tipo de camera)
    if str(camera_source).isnumeric(): # Caso USB
        frame_interval = 3
        # Setar Resolucao: W x H (Apenas USB)
        cap.set( 3, dlc.CONFIG["FRAME_WIDTH"] ) #1920)
        cap.set( 4, dlc.CONFIG["FRAME_HEIGHT"] ) #1080)
    else:
        frame_interval = cap.get(cv2.CAP_PROP_FPS) 

    # Exibir detalhe (debug mode)
    if dlc.CONFIG["DEBUG"]:
        dlc.console('Config: 1 Reconhecimento por '+str(frame_interval)+' Frame(s)')

    # Nome da janela
    window_name = str(dlc.CONFIG["SYSTEM_NAME"])+" ({})".format(camera_name)    
    if dlc.CONFIG["SHOW_FRAME"]:
        cv2.namedWindow(window_name)

    # Variaveis de captura (iniciais) - > Validar
    if cap.isOpened(): 
        ret, frame = cap.read()
    else:
        ret = False

    # Intervalo em segundos (display fps)
    fps_display_interval = 5 
    # Parametros de execucao do reconhecimento / display fps
    frame_rate = 0
    frame_count = 0
    start_time = time.time()

    # Eqto frame estiver disponivel
    while ret:
        
        # Captura do frame
        ret, frame = cap.read()
        
        if ret:
            
            if not str(camera_source).isnumeric(): # Caso IP
                frame = cv2.resize(frame, (dlc.CONFIG["FRAME_WIDTH"], dlc.CONFIG["FRAME_HEIGHT"])) 

            # Atingiu intervalo, dispara reconhecimento
            if (frame_count % frame_interval) == 0:

                # Exibir detalhe (debug mode)
                if dlc.CONFIG["DEBUG"]:
                    start_recognition = time.time()

                # Processar reconhecimento facial no frame
                faces = recognition.identify(frame)

                # Exibir detalhe (debug mode)
                if dlc.CONFIG["DEBUG"]:
                    elapsed = round(time.time()-start_recognition, 3)
                    dlc.console('Origem: {_camera}\nTempo de proc.: {_elapsed}s\nFaces: {_faces}\n'.format( 
                                    _camera = camera_name,
                                    _elapsed = elapsed, 
                                    _faces = [{"nome": face.name, 
                                            "prob." : round(face.probability, 3)*100, 
                                            "L2": round(face.l2, 3)} for face in faces]
                                )
                            )
                                
                # Validar FPS atual (caso extrapolar intervalo definido, atualiza variaveis)
                end_time = time.time()
                if (end_time - start_time) > fps_display_interval:
                    frame_rate = int(frame_count / (end_time - start_time))
                    start_time = time.time()
                    frame_count = 0
            # Atualiza contador de frames
            frame_count += 1

            # Adiconar marcacoes e exibir resultado
            if dlc.CONFIG["SHOW_OVERLAYS"]:
                cv_utils.add_overlays(frame, faces, frame_rate)
            if dlc.CONFIG["SHOW_FRAME"]:
                cv2.imshow(window_name, frame)

        # Validar interrupcao da opecacao
        if cv2.waitKey(20) == 27:  # exit on ESC
            break

    # Remover camera da memoria
    if dlc.CONFIG["SHOW_FRAME"]:
        cv2.destroyWindow(window_name)

def main():

    # Threading vs. Mutiprocessing -> https://www.quantstart.com/articles/Parallelising-Python-with-Threading-and-Multiprocessing
    multiprocessing.Process(target=camera_proccessing,
                             args=("CAMERA_TEST", 0)).start()
    
if __name__ == '__main__':
    main()
