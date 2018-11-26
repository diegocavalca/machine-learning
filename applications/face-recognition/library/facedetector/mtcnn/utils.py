import os, sys
import numpy as np
from scipy import misc
import cv2

wdir =  os.getcwd()+'/../../library/'
sys.path.append(wdir)

import library.dlc as dlc

import pickle
import tensorflow as tf

# MTCNN e configuracoes
from library.facenet.src.align import detect_face as detector # MTCNN

gpu_memory_fraction = 0.3 
debug = False

class Face:
    def __init__(self):
        self.bounding_box = None
        self.image = None
        self.container_image = None
        self.embedding = None

class Mtcnn:
    # face detection parameters 
    minsize = dlc.CONFIG["MIN_SIZE_FACE"]  # Tamanho minimo de face (minimal face to detect
    threshold = dlc.CONFIG["MTCNN_THRESHOLD"]  # Threshold de passos sequenciais (detect threshold for 3 stages
    factor = dlc.CONFIG["MTCNN_FACTOR"]  # Fator de escala (scale factor for image pyramid

    def __init__(self, face_crop_size=dlc.CONFIG["CROP_SIZE"], face_crop_margin=dlc.CONFIG["PADDING_DETECTION"][0]):
        self.pnet, self.rnet, self.onet = self._setup_mtcnn()
        self.face_crop_size = face_crop_size
        self.face_crop_margin = face_crop_margin

    def _setup_mtcnn(self):
        with tf.Graph().as_default():
            gpu_options = tf.GPUOptions(per_process_gpu_memory_fraction=gpu_memory_fraction)
            sess = tf.Session(config=tf.ConfigProto(gpu_options=gpu_options, log_device_placement=False))
            with sess.as_default():
                return detector.create_mtcnn(sess, None)

# Instanciando modelo RNA MTCNN
mtcnn = Mtcnn()

def find_faces(p_frame):
    frame = np.copy(p_frame)
    faces = []

    bounding_boxes, _ = detector.detect_face(frame, mtcnn.minsize,
                                            mtcnn.pnet, mtcnn.rnet, mtcnn.onet,
                                            mtcnn.threshold, mtcnn.factor)
    for bb in bounding_boxes:
        face = Face()
        face.container_image = frame
        face.bounding_box = np.zeros(4, dtype=np.int32)

        img_size = np.asarray(frame.shape)[0:2]
        face.bounding_box[0] = np.maximum(bb[0] - mtcnn.face_crop_margin / 2, 0)
        face.bounding_box[1] = np.maximum(bb[1] - mtcnn.face_crop_margin / 2, 0)
        face.bounding_box[2] = np.minimum(bb[2] + mtcnn.face_crop_margin / 2, img_size[1])
        face.bounding_box[3] = np.minimum(bb[3] + mtcnn.face_crop_margin / 2, img_size[0])
        cropped = frame[face.bounding_box[1]:face.bounding_box[3], face.bounding_box[0]:face.bounding_box[2], :]
        face.image = misc.imresize(cropped, (mtcnn.face_crop_size, mtcnn.face_crop_size), interp='bilinear')

        faces.append(face)
        break

    return faces

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
                              #boxPositions, boxSizes,
                              #(x - padding[0], y - padding[1]), (w + x + padding[0], h + y + padding[1]),
                              (x, y), (w, h),
                              boxColor, boxLine)

    except Exception as e:
        dlc.console( "Erro: " + str(e) )
    return frame

# class Mtcnn:
#     # face detection parameters 
#     minsize = 20  # minimum size of face
#     threshold = [0.6, 0.7, 0.7]  # three steps's threshold
#     factor = 0.709  # scale factor

#     def __init__(self, face_crop_size=160, face_crop_margin=32):
#         self.pnet, self.rnet, self.onet = self._setup_mtcnn()
#         self.face_crop_size = face_crop_size
#         self.face_crop_margin = face_crop_margin

#     def _setup_mtcnn(self):
#         with tf.Graph().as_default():
#             gpu_options = tf.GPUOptions(per_process_gpu_memory_fraction=gpu_memory_fraction)
#             sess = tf.Session(config=tf.ConfigProto(gpu_options=gpu_options, log_device_placement=False))
#             with sess.as_default():
#                 return align.detect_face.create_mtcnn(sess, None)

#     def find_faces_x(self, frame):
#         faces = []

#         bounding_boxes, _ = align.detect_face.detect_face(frame, self.minsize,
#                                                           self.pnet, self.rnet, self.onet,
#                                                           self.threshold, self.factor)
#         for bb in bounding_boxes:
#             face = Face()
#             face.container_image = frame
#             face.bounding_box = np.zeros(4, dtype=np.int32)

#             img_size = np.asarray(frame.shape)[0:2]
#             face.bounding_box[0] = np.maximum(bb[0] - self.face_crop_margin / 2, 0)
#             face.bounding_box[1] = np.maximum(bb[1] - self.face_crop_margin / 2, 0)
#             face.bounding_box[2] = np.minimum(bb[2] + self.face_crop_margin / 2, img_size[1])
#             face.bounding_box[3] = np.minimum(bb[3] + self.face_crop_margin / 2, img_size[0])
#             cropped = frame[face.bounding_box[1]:face.bounding_box[3], face.bounding_box[0]:face.bounding_box[2], :]
#             face.image = misc.imresize(cropped, (self.face_crop_size, self.face_crop_size), interp='bilinear')

#             faces.append(face)

#         return faces

# 		# if face.name is not None:
# 		# 	cv2.putText(frame, face.name, (face_bb[0], face_bb[3]),
# 		# 				cv2.FONT_HERSHEY_SIMPLEX, 1, color,
# 		# 				thickness=2, lineType=2)
# 	# cv2.putText(frame, str(frame_rate) + " fps", (10, 30),
# 	#             cv2.FONT_HERSHEY_SIMPLEX, 1, color,
# 	#             thickness=2, lineType=2)