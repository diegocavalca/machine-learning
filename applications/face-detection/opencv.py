import os, cv2

# Cascade detector
face_cascade = cv2.CascadeClassifier('./opencv/data/haarcascades/haarcascade_frontalface_alt.xml')

# Camera / parameters
cap = cv2.VideoCapture(0)
PADDING = 20

# while not cap.isOpened():
# 	...

while cap.isOpened():
	# Capture frame-by-frame
	ret, frame = cap.read()
	if ret:
		# Detection
		try:
			gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
			faces = face_cascade.detectMultiScale(gray, 1.2, 5)
			for (x,y,w,h) in faces:
				cv2.rectangle(frame, (x - PADDING, y - PADDING), (w+x + PADDING,h+y + PADDING), (0, 0, 255), 1)
		except Exception as e:
			print('Error -> ' + str(e))

	# Display the resulting frame
	cv2.imshow('Face Detection - Haarcascade',	frame)
	if cv2.waitKey(1) & 0xFF == ord('q'):
		break

cap.release()
cv2.destroyAllWindows()

# Run (in applications folder):
# > sudo killall VDCAssistant; python face-detection/opencv.py
#
# ...
#
# Ref: http://www.bogotobogo.com/python/OpenCV_Python/python_opencv3_Image_Object_Detection_Face_Detection_Haar_Cascade_Classifiers.php