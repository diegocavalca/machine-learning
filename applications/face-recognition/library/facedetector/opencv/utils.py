import os, sys
import numpy as np
from scipy import misc

wdir =  os.getcwd()+'/../../library/'
sys.path.append(wdir)

import library.dlc as dlc

import cv2

# Carrega o modelo de detecao em memoria (baseado em "cascata" de validacao do frame)
#frontal_face_model = 'library/facedetector/opencv/lbpcascade_frontalface_improved.xml'
#frontal_face_model = 'library/facedetector/opencv/haarcascade_frontalface_alt.xml',
detector = cv2.CascadeClassifier( dlc.CONFIG["HAARCASCADE_FACE_FILE"] )
smileCascade = cv2.CascadeClassifier( dlc.CONFIG["HAARCASCADE_SMILE_FILE"] )

class Face:
    def __init__(self):
        self.bounding_box = None
        self.image = None
        self.container_image = None
        self.embedding = None

# find_faces: Método para extrair afces a partir do frame 
# (IMPORTANTE: Na versão inicial, o reconhecimento acontecerá individualmente - 1 face por vez)
# _ _ _
# frame              : imagem capturada pela camera
# scale_factor, 
#   min_neighbors, 
#   min_size         : parametros da funcao detectMultiScale (OpenCV)
# frontal_face_model : arquivo para extração de faces da imagem (OpenCV)
# face_crop_size     : tamanho da face retornada (padrao facenet)
# padding            : ajuste adicional em relacao a POSICAO e TAMANHO da caixa
# ajustSize          : ajuste adicional em relacao ao TAMANHO da caixa
# debug              : ativa modo de depuração 
def find_faces( frame, 
                scale_factor = 1.3,
                min_neighbors = 5,
                min_zise = dlc.CONFIG["MIN_SIZE_FACE"],
                face_crop_size = dlc.CONFIG["CROP_SIZE"], 
                padding = dlc.CONFIG["PADDING_DETECTION"],
                #adjustPosition = (-15, -70), 
                #adjustSize = (15, 50),
                debug = dlc.CONFIG["DEBUG"]):
    
    #if not os.path.exists(frontal_face_model):
    #     dlc.console( "Nao foi possivel carregar o modelo de face do OpenCV: " + frontal_face_model )
    
    boxes = []
    faces = []
    try:
        
        # Trata a imagem em canal de cinza (normalizacao de pixels)
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

        # Avalia presenca de face (inicialmente apenas 1), no frame
        # ---
        """ Funcao detectMultiScale* é chamada para detectar objetos. No caso, usando o "Face Cascade", detectara faces.
        Argumentos:
        -> "frame": imagem a ser avaliada, que é normalizada em canal de cinza, para diminuir o espaço de busca.
        -> "scaleFactor": controla a proporção de tamanho de objetos (objetos longe da camera, aparecem
        menor, e vice-versa).
        -> "minNeighbors": define a quantidade de objetos positivos próximos ao atual para declará-lo como localizado, 
        uma vez que o OpenCV utiliza uma janela deslizante para detectar objetos.
        -> "minSize": controla o tamanho de cada janela deslizante (possivel objeto). 
        # ---
        * https://docs.opencv.org/2.4/modules/objdetect/doc/cascade_classification.html#cascadeclassifier-detectmultiscale"""
        bounding_boxes = detector.detectMultiScale(
                    gray,
                    scaleFactor = scale_factor,
                    minNeighbors = min_neighbors,
                    minSize = (min_zise, min_zise)
                )

        for bb in bounding_boxes:
            face = Face()
            face.container_image = frame
            face.bounding_box = np.zeros(4, dtype=np.int32)

            img_size = np.asarray(frame.shape)[0:2]
            face.bounding_box[0] = int(bb[0] - padding[0])
            face.bounding_box[1] = int(bb[1] - padding[1])
            face.bounding_box[2] = int(bb[0] + bb[2] + padding[0])
            face.bounding_box[3] = int(bb[1] + bb[3] + padding[1])
            cropped = frame[face.bounding_box[1]:face.bounding_box[3], face.bounding_box[0]:face.bounding_box[2], :]
            face.image = misc.imresize(cropped, (face_crop_size, face_crop_size), interp='bilinear')
            
            faces.append(face)
            #break

    except Exception as e:
        dlc.console( "Erro: " + str(e) )

    return faces

# draw_boxes: Mapear (desenhar) caixas para cada face detectada no frame
# _ _ _
# frame         : imagem capturada pela camera
# boxes         : faces reconhecidas no frame (matriz de faces [w, y, w, h])
# boxColor      : cor da caixa (RGB)
# boxLine       : expessura da linha da caixa
# padding : ajuste adicional em relacao a POSICAO e TAMANHO da caixa
# debug         : ativa modo de depuração 
def draw_boxes(p_frame, faces, 
        boxColor = dlc.CONFIG["BOX_COLOR"], boxLine = dlc.CONFIG["BOX_LINE"], 
        padding = dlc.CONFIG["PADDING_DETECTION"],
        frame_rate = 0, 
        debug = True):
    frame = np.copy(p_frame)
    try:
        if debug:
            dlc.console( "Faces detectadas: " + str( len(faces) ) )

        if faces is not None:
            for face in faces:
                face_bb = face.bounding_box.astype(int)
                (x, y, w, h) = (face_bb[0], face_bb[1], face_bb[2], face_bb[3])
                cv2.rectangle(frame,
                              (x - padding[0], y - padding[1]), (w + padding[0], h + padding[1]),
                              boxColor, boxLine)

    except Exception as e:
        dlc.console( "Erro: " + str(e) )
    return frame

def check_smile(frame, bounding_box):

    boxes = []
    _status = False
    try:

        # Trata a imagem em canal de cinza (normalizacao de pixels)
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        smiles = smileCascade.detectMultiScale(
                gray,
                scaleFactor= 1.7,
                minNeighbors=22,
                minSize=(25, 25) )
        
        if len(smiles) > 0:

            _status = True
            if dlc.CONFIG["DEBUG"]:
                print( "Sorriso encontrado: ", len(smiles) )

            for (x, y, w, h) in smiles:
                boxes.append( (x + bounding_box[0], 
                               y + bounding_box[1], 
                               w, h) )

    except Exception as e:
        dlc.console( "Erro: " + str(e) )

    return _status, boxes
#
# def draw_boxes_OLD(frame, boxes, boxColor = (255, 255, 255), boxLine = 1, 
#         adjustPosition = (-10, -50), adjustSize = (10, 20), debug = True):
    
#     nFrame = np.copy(frame)

#     try:

#         if debug:
#             dlc.console( "Faces detectadas: " + str( len(boxes) ) )

#         for (x, y, w, h) in boxes:
#             boxPositions = (x + adjustPosition[0], y + adjustPosition[1])
#             boxSizes = (x + w + adjustSize[0], y + h + adjustSize[1])
#             cv2.rectangle(nFrame, boxPositions, boxSizes, boxColor, boxLine)

#     except Exception as e:
#         dlc.console( "Erro: " + str(e) )

#     return nFrame


# extractFaces: Extrair face(s - futuramente) detectada no frame
# _ _ _
# frame         : imagem capturada pela camera
# boxes         : face(s) reconhecidas no frame (matriz de faces [w, y, w, h])
# fixedSize     : tamanho fixo ou nao da imagem de face ((96, 96) padrao FaceNet)
# boxSizes      : caso seja estabelecido tamanho fixo, a imagem da face é reajustada
# ajustPosition : ajuste adicional em relacao a POSICAO da caixa
# ajustSize     : ajuste adicional em relacao ao TAMANHO da caixa
# debug         : ativa modo de depuração 
#
# def extract_faces(frame, boxes, fixedSize = False, size = (96, 96), 
#         adjustPosition = (-10, -50), adjustSize = (10, 20), debug = True):
    
#     nFrame = np.copy(frame)
#     try:
#         for (x, y, w, h) in boxes:
#             nFrame = nFrame[ y + adjustPosition[1] : y + h + adjustSize[1], 
#                              x + adjustPosition[0]: x + w + adjustSize[0] ]
#             if fixedSize:
#                 nFrame = cv2.resize(nFrame, size) #, interpolation = cv.INTER_CUBIC)


#     except Exception as e:
#         dlc.console( "Erro: " + str(e) )

#     return nFrame
