import time, os, sys
ROOT_DIR = os.path.dirname(os.path.abspath(__file__)) + '/../'
#print(ROOT_DIR)
#sys.path.append(wdir)

# Configuracoes do sistema
CONFIG = {}

# Conjuntos de dados
DATASET = 'demo'#'master-19092018'
CONFIG["DATASET_TRAIN_PATH"] = os.path.join(ROOT_DIR, 'dataset/'+DATASET)
if not os.path.isdir(CONFIG["DATASET_TRAIN_PATH"]):
	os.mkdir(CONFIG["DATASET_TRAIN_PATH"])
# Imagens das capturas	
CONFIG["DATASET_CAPTURE_PATH"] = os.path.join(ROOT_DIR, 'dataset/'+DATASET+'-capture')
if not os.path.isdir(CONFIG["DATASET_CAPTURE_PATH"]):
	os.mkdir(CONFIG["DATASET_CAPTURE_PATH"])

# Arquivando registros de desconhecidos
# CONFIG["DATASET_UNKNOWN_PATH"] = os.path.join(ROOT_DIR, 'dataset/'+DATASET+'-unknown')
# if not os.path.isdir(CONFIG["DATASET_UNKNOWN_PATH"]):
# 	os.mkdir(CONFIG["DATASET_UNKNOWN_PATH"])#
#
# Arquivando video de registros (posterior validacao - video)
CONFIG["DATASET_RECORD_REGISTER"] = os.path.join(ROOT_DIR, 'dataset/'+DATASET+'-records')
if not os.path.isdir(CONFIG["DATASET_RECORD_REGISTER"]):
	os.mkdir(CONFIG["DATASET_RECORD_REGISTER"])

# Modelo FaceNet, Classificador SVM e demais configuracoes do pipeline
CONFIG["MODEL_PATH"] = 'library/facenet/models/'#os.path.join(ROOT_DIR, 'library/facenet/models/')
CONFIG["MODEL_FILE"] = os.path.join(CONFIG["MODEL_PATH"], '20180402-114759/20180402-114759.pb') # VGGFace2 https://github.com/davidsandberg/facenet/wiki/Training-using-the-VGGFace2-dataset
#'vggface2-cl/model.pb')#
CONFIG["EMBEDDING_SIZE"] = 512 # Default: 512
CONFIG["CLASSIFIER_FILE"] = os.path.join(CONFIG["MODEL_PATH"], 'clf-'+DATASET+'.pkl')#'classifier-03082018_193335.pkl')
CONFIG["UNKNOWN_THRESHOLD"] = 1.2 # Default: 1.2

# Ajustes de deteccao
CONFIG["MIN_SIZE_FACE"] = 40 # Default: 80(20)
CONFIG["MTCNN_FACTOR"] = 0.709 # Default: 0.709
CONFIG["MTCNN_THRESHOLD"] = [0.6, 0.7, 0.7]
CONFIG["FRAME_WIDTH"] = 640 # VGA (default) -> (640, 480) / FULL HD -> (1920, 1080) # Ref.: https://pt.wikipedia.org/wiki/Lista_de_resolu%C3%A7%C3%B5es_de_v%C3%ADdeo
CONFIG["FRAME_HEIGHT"] = 480 # ...
CONFIG["FRAME_SCALE"] = 1 # Dafault: 1
CONFIG["BOX_COLOR"] = (15, 196, 241)  # Default: (0, 255, 0)
CONFIG["BOX_LINE"] = 1 # Default: 1
CONFIG["FONT_COLOR"] = (255, 168, 0) # Default: (255, 255, 255)
CONFIG["FONT_SIZE"] = .45 # Default: .45
CONFIG["PADDING_DETECTION"] = (24, 24)  # Default: (32, 32)
CONFIG["CROP_SIZE"] = 160 # Default: 160
CONFIG["HAARCASCADE_FACE_FILE"] = os.path.join(ROOT_DIR, 'library/facedetector/opencv/haarcascade_frontalface_alt.xml') #frontal_face_model = 'library/facedetector/opencv/haarcascade_frontalface_alt.xml',
CONFIG["HAARCASCADE_SMILE_FILE"] = os.path.join(ROOT_DIR, 'library/facedetector/opencv/haarcascade_smile.xml')
CONFIG["LANDMARKS"] = 68 # Default: 68
CONFIG["DLIB_PREDICTOR_FILE"] = os.path.join(ROOT_DIR, 'library/facedetector/dlib/shape_predictor_{}_face_landmarks.dat'.format(CONFIG["LANDMARKS"]))
CONFIG["EMOTION_DETECTOR_MODEL_FILE"] = os.path.join(ROOT_DIR, 'library/emotion/cnn3.h5')
CONFIG["AUTO_CAPTURE"] = False

# Outras configs.
CONFIG["DEBUG"] = False
CONFIG["SYSTEM_NAME"] = "DLC | Tensorflow Face Recognition System"
CONFIG["SHOW_FRAME"] = True
CONFIG["SHOW_OVERLAYS"] = True
CONFIG["FULLSCREEN"] = False
CONFIG["RECORD_REGISTER"] = True # Gravar videos do registro (testes e validacoes posteriores ao registro)
CONFIG["TRASH_FILES"] = ['desktop.ini', '.DS_Store']#, 'thumbs.db']


def console(message):
	now = time.strftime("%d/%m/%Y %H:%M:%S")
	print( "{} -> {}".format(now, message) )