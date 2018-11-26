import sys, os, time, cv2, glob

wdir =  os.path.dirname(__file__) + "/../src"
sys.path.append(wdir)

# Recursos adicionais: configuracoes e utilitario de visao computacional.
from library import dlc

print('\nValidando tamanho das imagens em "{}", aguarde...'.format(dlc.CONFIG["DATASET_TRAIN_PATH"].split('/')[-1]))
# Registros
total = 0
resized = []
original = []
for folder in os.walk(dlc.CONFIG["DATASET_TRAIN_PATH"]):
	# Imagens p/ registro
	for file in glob.glob(folder[0]+"/*.jpg"):
		total += 1
		image = cv2.imread(file)
		if image.shape[1] < 160 or image.shape[0] > 160:
			resized.append(file)
			original.append(image.shape[:2])
			image = cv2.resize(image, (dlc.CONFIG["CROP_SIZE"],dlc.CONFIG["CROP_SIZE"]), interpolation = cv2.INTER_LINEAR)
			cv2.imwrite(file, image)


print('\nRESUMO FINAL')
print('============================================')
print('Total de imagens verificadas: '+ str(total))
print('Total de imagens ajustadas: ' + str(len(resized)) )
if len(resized)>0:
    print('Detalhes:')
    for f, file in enumerate(resized):
        print('{} -> Original: {}'.format( os.path.basename(file), original[f] ))
print('')