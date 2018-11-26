import sys, subprocess, platform, time, os, glob, requests
import numpy as np

from PyQt5.QtWidgets import (QApplication, QComboBox, QDialog, QMessageBox,
        QDialogButtonBox, QFormLayout, QGridLayout, QGroupBox, QHBoxLayout,
        QLabel, QLineEdit, QMenuBar, QPushButton, QSpinBox, QTextEdit, QVBoxLayout)

import cv2, dlib
from library import dlc # Utilitarios proprios
#from library.facedetector.opencv import utils as face_detector # Deteccao de faces (OpenCV-based)
from library.facedetector.mtcnn import utils as face_detector # Deteccao de faces (MTCNN)
from library.facedetector.dlib import utils as landmarks_detector # Deteccao de landmarks

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

# # # # # # # # INICIAR SISTEMA DE REGISTRO # # # # # # # #
# Camera
camera_source = 0
#camera_source = input("Digite a camera-alvo (codigo ou endereco): ")
camera_name = "Registro"

# Instanciar camera
if str(camera_source).isnumeric(): # Caso USB
    camera_source = int(camera_source)
cap = cv2.VideoCapture(camera_source)

# Ajustando parametros RESOLUCAO (se possivel - USB) e FPS (IP)
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
    dlc.console('Config: 1 Deteccao por '+str(frame_interval)+' Frame(s)')

# Gravar registro
if dlc.CONFIG["RECORD_REGISTER"]:
    video_recorder = cv2.VideoWriter(
                        os.path.join(
                            dlc.CONFIG["DATASET_RECORD_REGISTER"], 
                            'register-{}.avi'.format(
                                    len(glob.glob(dlc.CONFIG["DATASET_RECORD_REGISTER"]+"/*.avi"))
                                ) 
                            ), 
                        cv2.VideoWriter_fourcc(*'XVID'), frame_interval, 
                        (dlc.CONFIG["FRAME_WIDTH"], dlc.CONFIG["FRAME_HEIGHT"]))

# Nome da janela
window_name = str(dlc.CONFIG["SYSTEM_NAME"])+" ({})".format(camera_name)    
if dlc.CONFIG["SHOW_FRAME"]:
    cv2.namedWindow(window_name)

# Variaveis de captura (iniciais) - > Validar
if cap.isOpened(): 
    ret, frame = cap.read()
else:
    ret = False
# # # # # # # # SISTEMA DE REGISTRO INICIALIZADO # # # # # # # #

# Register: classe de dados do registro
class Register():
    def __init__(self):
        self.id = None
        self.name = None
# Instanciar classe de dados que serao cadastrados
register = Register()

# Dialog: classe da caixa de informacoes do registro
class Dialog(QDialog):
    NumGridRows = 2
    NumButtons = 4
 
    def __init__(self):
        super(Dialog, self).__init__()
        
        cv2.destroyAllWindows()

        self.formGroupBox = QGroupBox("Dados")
        layout = QFormLayout()
        
        lbl_id = QLabel("ID:")
        self.input_id = QLineEdit()
        layout.addRow(lbl_id, self.input_id)

        lbl_name = QLabel("Nome:")
        self.input_name = QLineEdit()
        layout.addRow(lbl_name, self.input_name)

        self.formGroupBox.setLayout(layout)
 
        buttonBox = QDialogButtonBox(QDialogButtonBox.Ok)
        buttonBox.clicked.connect(self.click)
 
        mainLayout = QVBoxLayout()
        mainLayout.addWidget(self.formGroupBox)
        mainLayout.addWidget(buttonBox)
        self.setLayout(mainLayout)
        self.setWindowTitle("Novo Registro")
 
    def click(self):
        _id = self.input_id.text()
        if not _id:
            _id = None
        _name = self.input_name.text()
        if not _name:
            _name = None
        
        if True:
            print("Id: " + str(_id))
            print("Nome: " + str(_name))

        # retornar
        register.id = _id
        register.name = _name

        self.close()
        camera_analisys(camera_source)

# camera_analisys: detectar face nas imagens da camera
def camera_analisys(camera_source = 0, ret = True):

    # Eqto frame estiver disponivel
    while ret:
        
        # Captura do frame
        ret, frame = cap.read()
        
        if ret:
            
            if not str(camera_source).isnumeric(): # Caso IP
                frame = cv2.resize(frame, (dlc.CONFIG["FRAME_WIDTH"], dlc.CONFIG["FRAME_HEIGHT"])) 


            # Gravar registro
            if dlc.CONFIG["RECORD_REGISTER"]:
                # Validar tamanho do frame (Qimg -> Apenas VGA ou FULLHD)
                video_recorder.write(frame)


            # Exibir detalhe (debug mode)
            if dlc.CONFIG["DEBUG"]:
                start_recognition = time.time()

            # Processar deteccao facial no frame (Localizar faces no frame (Validar depois))
            faces = face_detector.find_faces(frame)

            # Exibir detalhe (debug mode)
            if dlc.CONFIG["DEBUG"]:
                dlc.console('Origem: {_camera} / Tempo de proc (deteccao).: {_elapsed}s'.format(
                        _camera = camera_source,
                        _elapsed = round(time.time()-start_recognition, 3)
                    ))

            # Processar faces e mostrar informacoes em tela
            if len(faces)>0:
                # Captura Automatica
                if dlc.CONFIG["AUTO_CAPTURE"]:
                    #print("S")
                    for face in faces:
                        save_register(face.image)

                #main_face = faces[0] # Apenas a face em primeiro-plano
                frame = face_detector.draw_boxes(frame, faces)
                
                # Montar imagens
                face = faces[0].image
                text_detection = 'Face detectada'
            else:
                face = np.zeros((dlc.CONFIG["CROP_SIZE"], dlc.CONFIG["CROP_SIZE"]))
                text_detection = 'Nenhuma face detectada'            

            # Detalhes deteccao
            frame[0:25, 0:dlc.CONFIG["FRAME_WIDTH"], :] = 255
            # ID
            _id = register.id
            if _id is None:
                _id = '(Nenhum)'
            # Nome
            _name = register.name
            if _name is None:
                _name = '(Nenhum)'
            cv2.putText(frame, 'DADOS > Id: {}, Nome: {}, Fotos: {} | STATUS > {}'.format(
                    _id,
                    _name,
                    count_register_photos(_id, _name),
                    text_detection
                ), 
                (5, 15), cv2.FONT_HERSHEY_SIMPLEX, .45, (0,0,0), 1)

            # Comandos:
            frame[dlc.CONFIG["FRAME_HEIGHT"]-25:dlc.CONFIG["FRAME_HEIGHT"], 
                0:dlc.CONFIG["FRAME_WIDTH"], :] = 0
            cv2.putText(frame, 'COMANDOS > [N] = Novo Registro [ENTER] = Salvar Face Atual | [ESC] = Sair', 
                (5, dlc.CONFIG["FRAME_HEIGHT"]-10), 
                cv2.FONT_HERSHEY_SIMPLEX, .4, (255,255,255), 1)

            # Exibir frames em tela
            cv2.imshow(window_name, frame)
            cv2.imshow("Face Detectada", face)

        
        # Validar comandos
        k = cv2.waitKey(33)
        #print('key -> '+ str(k))
        # ESC - Finalizar da opecacao
        if k == 27:    # Esc key to stop
            break
        # N - Novo registro
        elif k == 110:
            Dialog().exec_()
        # ENTER / BACKSPACE - Salvar imagem
        elif k in [13, 32] and dlc.CONFIG["AUTO_CAPTURE"] == False:
            #print("S")
            save_register(face)
        else:
            continue

    cap.release()
    cv2.destroyAllWindows()

# count_register_photos: contabilizar o numero de fotos do registro
def count_register_photos(_id = None, _name = None ):

    if _id is not None and _name is not None and _id != '(Nenhum)' and _name != '(Nenhum)':
        # Contagem dos arquivos do usuario
        _name = str(_name).lower().replace(" ","_")
        _id = str(_id).lower().replace(" ","_")
        total = 0
        if _name and _id:
            # Totalizar imagens arquivadas para o cadastro
            _filename = _name+"-"+_id
            #_folder_facenet =os.path.join("dataset", "original", _filename)
            _folder_facenet = os.path.join(dlc.CONFIG["DATASET_TRAIN_PATH"], _filename)
            total = 0
            if os.path.isdir(_folder_facenet):
                total += len(glob.glob(_folder_facenet+"/*.jpg"))
                total += len(glob.glob(_folder_facenet+"/*.png"))
    else:
        total = 0

    return total

# save_register: salvar foto da face na pasta do registro
def save_register(face, frame = None):
    if register.id and register.name:

        if not np.all(face == 0):
            _img = face

            # Nome do arquivo (imagem)
            _nome = str(register.name).lower().replace(" ","_")
            _id = str(register.id).lower().replace(" ","_")
            _filename = _nome+"-"+_id

            # Pastas de armazenamento das imagens (captura / facenet-original)
            #_folder_facenet = os.path.join("dataset", "captura", _filename)
            _folder_captura = os.path.join(dlc.CONFIG["DATASET_CAPTURE_PATH"], _filename)
            if not os.path.isdir(_folder_captura):
                os.mkdir(_folder_captura)
            #_folder_facenet = os.path.join("dataset", "original", _filename)
            _folder_facenet = os.path.join(dlc.CONFIG["DATASET_TRAIN_PATH"], _filename)
            if not os.path.isdir(_folder_facenet):
                os.mkdir(_folder_facenet)
            
            # Nomeando o arquivo
            #_total = int(sum([len(files) for r, d, files in os.walk(_folder_facenet)]))
            _total = 1
            _total += len(glob.glob(_folder_facenet+"/*.jpg"))
            _total += len(glob.glob(_folder_facenet+"/*.png"))
            arquivo = _filename + "_" + str(_total) + ".jpg"
            arquivo_captura = os.path.join(_folder_captura, arquivo)
            arquivo_facenet = os.path.join(_folder_facenet, arquivo)

            try:
                # Imagem orgiginal (cena frame)
                if frame:
                    cv2.imwrite(arquivo_captura, frame)
                # Padrao facenet (apenas face)
                #_resized_img = cv2.resize(_img, (160, 160))  # VALIDAR!!!
                cv2.imwrite(arquivo_facenet, _img)
                
            except Exception as e:
                dlc.console("Erro ao salvar imagem: "+str(e))
        else:
            if dlc.CONFIG["DEBUG"]:
                dlc.console("Erro -> Nenhuma face detectada na imagem, tente novamente!")
            QMessageBox.warning(None, "Erro", "Nenhuma face detectada na imagem, tente novamente!")
    else:
        if dlc.CONFIG["DEBUG"]:
            
            dlc.console("Erro -> Campos 'Nome' e 'Identificador' são obrigatórios!")
        QMessageBox.warning(None, "Erro", "Campos 'Nome' e 'Identificador' são obrigatórios!")

if __name__ == '__main__':
    app = QApplication(sys.argv)
    dialog = Dialog()
    
sys.exit(dialog.exec_())
    