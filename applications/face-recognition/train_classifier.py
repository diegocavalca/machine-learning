from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import argparse, os, sys, time, math, pickle
#wdir =  os.getcwd()+'/library/'
#sys.path.append(wdir)

from library import dlc
from library.facenet.src import facenet

#import detect_face
from sklearn.svm import SVC
from sklearn.neighbors import KNeighborsClassifier
import tensorflow as tf
import numpy as np

debug = True

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

# Diretorio dos modelos (facenet e classificador SVM)
MODEL_DIR = 'library/facenet/models/'
FACENET_MODEL_PATH = os.path.join(MODEL_DIR, '20180402-114759/20180402-114759.pb')

with tf.Graph().as_default():

    with tf.Session() as sess:

        try:
            # Organizando dataset
            if debug:
                print('Organizando dataset...', end='')

            #datadir = 'dataset/final'
            #datadir = 'dataset/original'
            dataset = facenet.get_dataset(dlc.CONFIG["DATASET_TRAIN_PATH"])
            images, names = facenet.get_image_paths_and_labels(dataset)
            
            # Filtrando apenas imagens (JPEG, limpando lixo dos SO's)
            paths, labels = [], []
            for idx, image in enumerate(images):
                extension = image.lower().split(".")[-1]
                if extension in ['jpg', 'png']:
                    paths.append(image)
                    labels.append(names[idx])

            if debug:
                print(' Ok!')

                print('Numero de cadastros (pessoas): %d' % len(dataset))
                print('Numero de imagens: %d' % len(paths))

                #print(paths)
                print('Carregando modelo de extracao de caracteristicas -> ', end='')
            
            # Carregando modelo (RNA pre-treinada)
            #modeldir = 'facenet/model-20170512-110547.pb'
            facenet.load_model(dlc.CONFIG["MODEL_FILE"])
            if debug:
                print('... Ok!')

                print('Calcular parâmetros por face (embeddings)... ', end='')
            
            # Passada para calcular os embeddings
            images_placeholder = tf.get_default_graph().get_tensor_by_name("input:0")
            embeddings = tf.get_default_graph().get_tensor_by_name("embeddings:0")
            phase_train_placeholder = tf.get_default_graph().get_tensor_by_name("phase_train:0")
            embedding_size = embeddings.get_shape()[1]

            batch_size = 52

            image_size = dlc.CONFIG["CROP_SIZE"]
            nrof_images = len(paths)
            nrof_batches_per_epoch = int(math.ceil(1.0 * nrof_images / batch_size))
            embeddings_set = np.zeros((nrof_images, embedding_size))
            for i in range(nrof_batches_per_epoch):
                start_index = i * batch_size
                end_index = min((i + 1) * batch_size, nrof_images)
                paths_batch = paths[start_index:end_index]
                images = facenet.load_data(paths_batch, False, False, image_size)
                feed_dict = {images_placeholder: images, phase_train_placeholder: False}
                embeddings_set[start_index:end_index, :] = sess.run(embeddings, feed_dict=feed_dict)
            if debug:
                print(' Ok!')

                print('Calibrando o classificador... ', end='')

            # Treinando classificador
            #model = SVC(kernel='linear', probability=True) # Original (Corretude: 98.49%)
            # Otimizado - 19092018
            #model = SVC(kernel='rbf', C=1000, gamma=0.001, probability=True) # 99.25%
            model = KNeighborsClassifier(algorithm='ball_tree', leaf_size=30, n_neighbors=5, weights='distance', p=1)

            # Ajuste
            model.fit(embeddings_set, labels)
            if debug:
                print('Ok!')

            # Lista com os cadastros (tratada)
            classes = [cls.name.replace('_', ' ') for cls in dataset]

            # Exportando o classificador (pickle)
            name_classifier = str(input('Nome do classificador (caso contrário, deixe em branco): '))
            if name_classifier:
                name_classifier = name_classifier.replace('.pkl','')
            else:
                #name_classifier = 'clf-{}'.format( time.strftime("%d%m%Y_%H%M%S") )                
                name_classifier = 'clf-{}'.format( dlc.DATASET )                
            name_classifier += '.pkl'

            #classifier = MODEL_DIR + name_classifier
            #classifier_file = os.path.expanduser(dlc.CONFIG["CLASSIFIER_FILE"])
            classifier_path = os.path.join(dlc.CONFIG["MODEL_PATH"], name_classifier)
            with open(classifier_path, 'wb') as classifier:
                pickle.dump((model, classes), classifier)

            # Exportar embeddings de cada classe
            idx_previous = 0
            for label in set(labels):
                # Nome da classe (cadastro)
                print(str(dataset[label]))
                name = str(dataset[label]).split(',')[0]
                #print(name)
                # Totalizando amostras
                total = labels.count( int(label) )
                # Recorte de embeddings da classe
                embeddings_class = embeddings_set[idx_previous:idx_previous+total]
                #print( embeddings_class )
                #print( embeddings_class.shape )
                # Salvando resultados
                np.save( os.path.join(dlc.CONFIG["DATASET_TRAIN_PATH"], name, 'embeddings.npy'), embeddings_class)

                idx_previous = total

            if debug:
                print('Classificador SVM salvo em "%s"!' % classifier_path)
        
        except Exception as e:
            dlc.console("Erro -> "+ str(e))