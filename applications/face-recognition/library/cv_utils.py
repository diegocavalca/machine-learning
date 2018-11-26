import cv2
from library import dlc


def add_overlays(frame, faces, frame_rate):
    if faces is not None:
        for face in faces:
            face_bb = face.bounding_box.astype(int)
            cv2.rectangle(frame,
                          (face_bb[0], face_bb[1]), (face_bb[2], face_bb[3]),
                          dlc.CONFIG["BOX_COLOR"], dlc.CONFIG["BOX_LINE"])
            if face.name is not None:
                cv2.putText(frame, face.name, 
                            (face_bb[0], face_bb[1]-20), 
                            cv2.FONT_HERSHEY_SIMPLEX, 
                            dlc.CONFIG["FONT_SIZE"], dlc.CONFIG["FONT_COLOR"], 1)
                cv2.putText(frame, '{}% / L2: {}'.format(
                                    round(face.probability*100, 2), 
                                    round(face.l2, 3)), 
                        (face_bb[0], face_bb[1]-5), 
                        cv2.FONT_HERSHEY_SIMPLEX, 
                        dlc.CONFIG["FONT_SIZE"], dlc.CONFIG["FONT_COLOR"], 1)
    
    cv2.putText(frame, str(frame_rate) + " fps", (frame.shape[1]-98, frame.shape[0]-10),
                cv2.FONT_HERSHEY_SIMPLEX, 1, dlc.CONFIG["FONT_COLOR"],
                thickness=2, lineType=2)

def increase_brightness(frame, value=30):
    hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
    h, s, v = cv2.split(hsv)

    lim = 255 - value
    v[v > lim] = 255
    v[v <= lim] += value

    final_hsv = cv2.merge((h, s, v))
    frame = cv2.cvtColor(final_hsv, cv2.COLOR_HSV2BGR)
    return frame