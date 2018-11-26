import cv2, sys, os
import keras
from scipy.misc import imresize
import numpy as np

wdir =  os.getcwd()+'/../../library/'
sys.path.append(wdir)

import library.dlc as dlc

# Constantes
EMOTIONS = ['raiva','repulsa', 'medo','alegria','tristeza', 'surpresa','neutro']
height = width = 20

# Carregando modelo
model = keras.models.load_model( dlc.CONFIG["EMOTION_DETECTOR_MODEL_FILE"] )

def detect(face):
    x = []
    result = None
    try:
        face = cv2.cvtColor(face, cv2.COLOR_RGB2GRAY)
        gray = imresize(face, [height, width], 'bilinear')
        gray = np.dstack((gray,) * 3)
        x.append(gray)
        x = np.asarray(x)
        result = model.predict( x, batch_size=8, verbose=0)
    except Exception as e:
        dlc.console( "Erro deteccao emocao: " + str(e) )
    return result

def plot(p_frame, result, color_text = (0, 0, 255), color_chart = (255, 0, 0), margin_top = 60):
    frame = np.copy(p_frame)
    try:
        for index,emotion in enumerate(EMOTIONS):
            cv2.putText(frame, emotion, (10,index * 20 + 20 + margin_top), cv2.FONT_HERSHEY_PLAIN, 1, color_text, 1);
            cv2.rectangle(frame, (130, index * 20 + 10 + margin_top), (130 + int(result[0][index] * 100), (index + 1) * 20 + 4 + margin_top), color_chart, -1)
    except Exception as e:
        dlc.console( "Erro plot emocoes: " + str(e) )
    return frame