import os

#from library.recognition import utils as recognizer
from library import dlc

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

dataset_dir = dlc.CONFIG["DATASET_TRAIN_PATH"]#'dataset/final'
model_path = dlc.CONFIG["MODEL_FILE"]#
classifier_path = dlc.CONFIG["CLASSIFIER_FILE"]#
batch_size = 100

split_dataset = False

# Avaliar em dataset train/test OU dataset todo (overfiting risk)
if split_dataset:
	p = os.popen('python library/facenet/src/classifier.py CLASSIFY "{}" {} {} --batch_size {} --min_nrof_images_per_class 3 --nrof_train_images_per_class 2 --use_split_dataset'.format(dataset_dir, model_path, classifier_path, batch_size, ))  
else:
	p = os.popen('python library/facenet/src/classifier.py CLASSIFY "{}" {} {} --batch_size {}'.format(dataset_dir, model_path, classifier_path, batch_size)) 	
print(p.read())  