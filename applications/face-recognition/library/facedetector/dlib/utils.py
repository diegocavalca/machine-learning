import os, sys
import numpy as np
from scipy import misc
import cv2

wdir =  os.getcwd()+'/../../library/'
sys.path.append(wdir)

import library.dlc as dlc

import dlib

from imutils.face_utils import FaceAligner
from imutils.face_utils import rect_to_bb

# Detector de face (HOG+SVM)
detector = dlib.get_frontal_face_detector()

# Preditor de Landmarks
#predictor = dlib.shape_predictor("library/facedetector/dlib/shape_predictor_68_face_landmarks.dat")
predictor = dlib.shape_predictor( dlc.CONFIG["DLIB_PREDICTOR_FILE"] )
aligner = FaceAligner(predictor, desiredFaceWidth=256)

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
# face_crop_size     : tamanho da face retornada (padrao facenet)
# face_crop_margin   : margem de recorte da imagem
# ajustPosition : ajuste adicional em relacao a POSICAO da caixa
# ajustSize     : ajuste adicional em relacao ao TAMANHO da caixa
# debug              : ativa modo de depuração 
def find_faces( p_frame, 
                #detector,
                scale_factor = 1.1,
                min_neighbors = 5,
                min_zise = 20,
                face_crop_size = dlc.CONFIG["CROP_SIZE"], 
                padding = dlc.CONFIG["PADDING_DETECTION"],
                debug = True):

    # Pre-processamento da imagem
    frame = np.copy(p_frame)
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    boxes = []
    faces = []
    try:
        # Detector HOG+SVM (dlib) / Realizando deteccao        
        rects = detector(gray, 1)
        
        if debug:
            print("Boxes: " + str(list(rects)))    

        for i, bb in enumerate(rects):
            face = Face()
            face.container_image = frame
            face.bounding_box = np.zeros(4, dtype=np.int32)

            # Delimitando face
            # x
            x = bb.left() - padding[0]
            face.bounding_box[0] = int( x )
            # y
            y = bb.top() - padding[1]
            face.bounding_box[1] = int( y )
            # w
            w = bb.right() + padding[0]
            face.bounding_box[2] = int( w - bb.left() )
            # h
            h = (bb.bottom() + padding[1])
            face.bounding_box[3] = int( h - bb.top() )

            if debug:
                print("BB (dlib): " + str(bb))
                print("BB (face): " + str(face.bounding_box))
            
            #cropped = frame[int(y):int(h), int(x):int(w), :]
            cropped = frame[face.bounding_box[1]: (h - padding[1]), 
                            face.bounding_box[0]: (w - padding[0]), :]
            face.image = misc.imresize(cropped, (face_crop_size, face_crop_size), interp='bilinear')
            #cv2.imshow('...', cropped)
            faces.append(face)
            #break

    except Exception as e:
        dlc.console( "Erro: " + str(e) )

    return faces#, rects

def draw_boxes(p_frame, faces, 
                boxColor = dlc.CONFIG["BOX_COLOR"], boxLine = dlc.CONFIG["BOX_LINE"], #= dlc.CONFIG["COLOR_DETECTION"], boxLine = dlc.CONFIG["LINE_DETECTION"], 
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
                              #boxPositions, boxSizes,
                              (x - padding[0], y - padding[1]), (w + x + padding[0], h + y + padding[1]),
                              boxColor, boxLine)

    except Exception as e:
        dlc.console( "Erro: " + str(e) )
    return frame

def bb_to_rect(bounding_box):
    (x,y,w,h) = [int(i) for i in bounding_box] # https://github.com/davisking/dlib/issues/545
    rect = dlib.rectangle(x,y,w,h)#x+w,y+h)
    return rect

def find_landmarks(p_frame, faces):
    frame = np.copy(p_frame)
    landmarks = []
    rect = None
    try:
        if len(faces)>0:
            #for face in faces:
            #(x,y,w,h) = [int(i) for i in faces[0].bounding_box] # https://github.com/davisking/dlib/issues/545
            #rect = dlib.rectangle(x,y,w,h)#x+w,y+h)
            rect = bb_to_rect(faces[0].bounding_box)
            landmarks = np.matrix([[p.x, p.y] for p in predictor(frame, rect).parts()])
    except Exception as e:
        dlc.console( "Erro aqui: " + str(e) )

    return landmarks, rect

def draw_landmarks(p_frame, landmarks, showLandmarksIdx = False):
    frame = np.copy(p_frame)
    try:
        if landmarks is not None:

            # Desenhar landmarks no frame
            #landmarks = landmarks[0]

            for idx, point in enumerate(landmarks):
                #print(point)
                pos = (point[0, 0], point[0, 1])
                cv2.circle(frame, pos, 3, color=(0, 255, 255))
                if showLandmarksIdx:
                    cv2.putText(frame, str(idx), pos,
                                fontFace=cv2.FONT_HERSHEY_SCRIPT_SIMPLEX,
                                fontScale=0.4,
                                color=(0, 0, 255))

    except Exception as e:
        dlc.console( "Erro draw: " + str(e) )
    
    return frame

def align(p_frame, rects = None, 
        landmarks = None, bounding_box = None):
    frame = np.copy(p_frame)
    # gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)    
    # rect = bb_to_rect(bounding_box)
    # aligned = aligner.align(frame, gray, rect)
    # return aligned

    # Find the 5 face landmarks we need to do the alignment.
    faces = dlib.full_object_detections()
    for detection in rects:
        #faces.append(predictor(frame, detection)) # Detectando faces
        if landmarks is None:
            landmarks = predictor(frame, detection)
            #landmarks = find_landmarks(frame, face)
        faces.append(landmarks)

    # Alinhando as faces
    image = dlib.get_face_chips(frame, faces, size=dlc.CONFIG["CROP_SIZE"])[0]

    return image

# Calculo (regressao) de posicao da cabeca
K = [6.5308391993466671e+002, 0.0, 3.1950000000000000e+002,
     0.0, 6.5308391993466671e+002, 2.3950000000000000e+002,
     0.0, 0.0, 1.0]
D = [7.0834633684407095e-002, 6.9140193737175351e-002, 0.0, 0.0, -1.3073460323689292e+000]
cam_matrix = np.array(K).reshape(3, 3).astype(np.float32)
dist_coeffs = np.array(D).reshape(5, 1).astype(np.float32)
object_pts = np.float32([[6.825897, 6.760612, 4.402142],
                         [1.330353, 7.122144, 6.903745],
                         [-1.330353, 7.122144, 6.903745],
                         [-6.825897, 6.760612, 4.402142],
                         [5.311432, 5.485328, 3.987654],
                         [1.789930, 5.393625, 4.413414],
                         [-1.789930, 5.393625, 4.413414],
                         [-5.311432, 5.485328, 3.987654],
                         [2.005628, 1.409845, 6.165652],
                         [-2.005628, 1.409845, 6.165652],
                         [2.774015, -2.080775, 5.048531],
                         [-2.774015, -2.080775, 5.048531],
                         [0.000000, -3.116408, 6.097667],
                         [0.000000, -7.415691, 4.070434]])
reprojectsrc = np.float32([[10.0, 10.0, 10.0],
                           [10.0, 10.0, -10.0],
                           [10.0, -10.0, -10.0],
                           [10.0, -10.0, 10.0],
                           [-10.0, 10.0, 10.0],
                           [-10.0, 10.0, -10.0],
                           [-10.0, -10.0, -10.0],
                           [-10.0, -10.0, 10.0]])
line_pairs = [[0, 1], [1, 2], [2, 3], [3, 0],
              [4, 5], [5, 6], [6, 7], [7, 4],
              [0, 4], [1, 5], [2, 6], [3, 7]]
def get_head_pose(shape):
    image_pts = np.float32([shape[17], shape[21], shape[22], shape[26], shape[36],
                            shape[39], shape[42], shape[45], shape[31], shape[35],
                            shape[48], shape[54], shape[57], shape[8]])

    _, rotation_vec, translation_vec = cv2.solvePnP(object_pts, image_pts, cam_matrix, dist_coeffs)
    reprojectdst, _ = cv2.projectPoints(reprojectsrc, rotation_vec, translation_vec, cam_matrix,
                                        dist_coeffs)
    reprojectdst = tuple(map(tuple, reprojectdst.reshape(8, 2)))
    # calc euler angle
    rotation_mat, _ = cv2.Rodrigues(rotation_vec)
    pose_mat = cv2.hconcat((rotation_mat, translation_vec))
    _, _, _, _, _, _, euler_angle = cv2.decomposeProjectionMatrix(pose_mat)

    return reprojectdst, euler_angle