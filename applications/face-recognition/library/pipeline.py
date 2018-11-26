# coding=utf-8
"""Face Detection and Recognition"""
# MIT License
#
# Copyright (c) 2017 François Gervais
#
# This is the work of David Sandberg and shanren7 remodelled into a
# high level container. It's an attempt to simplify the use of such
# technology and provide an easy to use facial recognition package.
#
# https://github.com/davidsandberg/facenet
# https://github.com/shanren7/real_time_face_recognition
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

import pickle
import os, sys

wdir =  os.getcwd()
sys.path.append(wdir)

import cv2
import numpy as np
import tensorflow as tf
from scipy import misc

# Libs do FaceNet e MTCNN
from library.facenet.src import facenet
from library.facenet.src.align import detect_face

# Lib de deteccao de faces na imagem (OpenCV-based)
from library.facedetector.opencv import utils as fd

# Configuracoes de execucao do Pipeline
from library import dlc
from scipy.spatial.distance import euclidean as L2

gpu_memory_fraction = 0.3
facenet_model_checkpoint = dlc.CONFIG["MODEL_FILE"]
classifier_model = dlc.CONFIG["CLASSIFIER_FILE"]
debug = dlc.CONFIG["DEBUG"]

class Face:
    def __init__(self):
        self.id = None
        self.name = None
        self.probability = None
        self.l2 = None
        self.bounding_box = None
        self.image = None
        self.container_image = None
        self.embedding = None

# Classe de Reconhecimento Facial: engloba, em alto nivel, todas as etapas da biometria facial (Facenet-based)
class Recognition:
    def __init__(self):
        if debug:
            print(' = = = = = = = = {} = = = = = = = ='.format(dlc.CONFIG["SYSTEM_NAME"]))
            print('Inicializando sistema, aguarde um minuto...')

        self.detector = Detection()     # Detecao (e alinhamento) de Face(s)
        self.encoder = Encoder()        # Codificacao da face (embedding - Forward-pass Facenet)
        self.identifier = Identifier()  # Identificacao (classificacao SVM/L2)

        if debug:
            print('Sistema inicializado com sucesso!')

    def add_identity(self, image, person_name):
        faces = self.detector.find_faces(image) # MTCNN
        #faces = fd.find_faces(frame) # OpenCV Based

        if len(faces) == 1:
            face = faces[0]
            face.name = person_name
            face.embedding = self.encoder.generate_embedding(face)
            return faces

    def identify(self, image):
        faces = self.detector.find_faces(image) # Detecta (e alinha) faces

        for i, face in enumerate(faces):
            #if debug:
            #    cv2.imshow("Face: " + str(i), face.image)
            face.embedding = self.encoder.generate_embedding(face) # Gera embedding
            face.id, face.name, face.probability, face.l2 = self.identifier.identify(face) # Reconhece

        return faces

# Classe de Deteccao de Faces (MTCNN-based)
class Detection:
    # Parametro de deteccao de face (valores padrao MTCNN)
    minsize = dlc.CONFIG["MIN_SIZE_FACE"]  # Tamanho minimo de face 
    threshold = [0.6, 0.7, 0.7]  # Threshold de passos sequenciais
    factor = dlc.CONFIG["MTCNN_FACTOR"]  # Fator de escala 

    def __init__(self, face_crop_size=160, face_crop_margin=32):
        if debug:
            print('Carregando rede neural de deteccao de faces (MTCNN)... ', end='')
        
        self.pnet, self.rnet, self.onet = self._setup_mtcnn()
        self.face_crop_size = face_crop_size
        self.face_crop_margin = face_crop_margin
        
        if debug:
            print('Ok!')

    def _setup_mtcnn(self):
        with tf.Graph().as_default():
            gpu_options = tf.GPUOptions(per_process_gpu_memory_fraction=gpu_memory_fraction)
            sess = tf.Session(config=tf.ConfigProto(gpu_options=gpu_options, log_device_placement=False))
            with sess.as_default():
                return detect_face.create_mtcnn(sess, None)

    def find_faces(self, image):
        faces = []

        bounding_boxes, _ = detect_face.detect_face(image, self.minsize,
                                                          self.pnet, self.rnet, self.onet,
                                                          self.threshold, self.factor)
        for bb in bounding_boxes:
            face = Face()
            face.container_image = image
            face.bounding_box = np.zeros(4, dtype=np.int32)

            img_size = np.asarray(image.shape)[0:2]
            face.bounding_box[0] = np.maximum(bb[0] - self.face_crop_margin / 2, 0)
            face.bounding_box[1] = np.maximum(bb[1] - self.face_crop_margin / 2, 0)
            face.bounding_box[2] = np.minimum(bb[2] + self.face_crop_margin / 2, img_size[1])
            face.bounding_box[3] = np.minimum(bb[3] + self.face_crop_margin / 2, img_size[0])
            cropped = image[face.bounding_box[1]:face.bounding_box[3], face.bounding_box[0]:face.bounding_box[2], :]
            face.image = misc.imresize(cropped, (self.face_crop_size, self.face_crop_size), interp='bilinear')

            faces.append(face)

        return faces

# Classe de codificacao das faces (FaceNet-based): gera embedding para a face detectada
class Encoder:
    def __init__(self):
        if debug:
            print('Carregando modelo de extracao de caracteristicas (FaceNet) -> ', end='')

        self.sess = tf.Session()
        with self.sess.as_default():
            facenet.load_model(facenet_model_checkpoint)

        if debug:
            print('... Ok!')

    def generate_embedding(self, face):
        # Instanciar tensores (entrada e saida)
        images_placeholder = tf.get_default_graph().get_tensor_by_name("input:0")
        embeddings = tf.get_default_graph().get_tensor_by_name("embeddings:0")
        phase_train_placeholder = tf.get_default_graph().get_tensor_by_name("phase_train:0")

        prewhiten_face = facenet.prewhiten(face.image)

        # Calculando embeddings
        feed_dict = {images_placeholder: [prewhiten_face], 
                    phase_train_placeholder: False}
        return self.sess.run(embeddings, feed_dict=feed_dict)[0]

# Classe de Identificação: Instancia classificador e identifica cada embedding
class Identifier:
    def __init__(self):
        if debug:
            print('Carregando o classificador -> {}... '.format(dlc.CONFIG["CLASSIFIER_FILE"]), end='')

        # Carregando classificador
        with open(classifier_model, 'rb') as infile:
            self.model, self.class_names = pickle.load(infile)

        if debug:
            print('Ok!')
            print('Pre-calculo de embeddings das faces conhecidas...', end='')

        self.embedding_registers = np.zeros((len(self.class_names), dlc.CONFIG["EMBEDDING_SIZE"]))
        for idx, class_ in enumerate(self.class_names):
            emb = np.load( os.path.join(dlc.CONFIG["DATASET_TRAIN_PATH"], class_.replace(' ','_'), 'embeddings.npy') )
            self.embedding_registers[idx, :] = emb.mean(axis=0)
        
        if debug:
            print(' Ok!')

    def identify(self, face):
        if face.embedding is not None:
            # Executar classificador
            predictions = self.model.predict_proba([face.embedding])
            # Probabilidade maxima
            best_class_indices = np.argmax(predictions, axis=1)
            Y_pred_idx = best_class_indices[0]

            # L2_values = []
            # for idx, class_ in enumerate(self.class_names):
            #     L2_value = L2(embedding_input, embeddings_register[idx, :])
            #     L2_values.append( L2_value )
            #     if debug:
            #         #print('Y_pred = {} ({})%'.format(Y_pred, metric))
            #         print( 'L2 {} -> {}'.format( class_, str(L2_value) ) )
            
            # Inferir l2
            Y_pred_l2 = L2(face.embedding, self.embedding_registers[Y_pred_idx, :])
            # Validar limiar de face conhecida
            if Y_pred_l2 < dlc.CONFIG["UNKNOWN_THRESHOLD"]:
                info = self.class_names[Y_pred_idx].split('-')
                Y_pred_id = info[-1]
                Y_pred_class = info[0].replace('_', '').title()
                Y_pred_prob = predictions[0][Y_pred_idx]
            else:
                Y_pred_id = 0
                Y_pred_class = 'Desconhecido'
                Y_pred_prob = 0
            return Y_pred_id, Y_pred_class, Y_pred_prob, Y_pred_l2


