/**
 * Created by chad hart on 11/30/17.
 * Client side of Tensor Flow Object Detection Web API
 * Written for webrtcHacks - https://webrtchacks.com
 */

//Parameters
const s = document.getElementById('objDetect');
const sourceVideo = s.getAttribute("data-source");  //the source video to use
const uploadWidth = s.getAttribute("data-uploadWidth") || 640; //the width of the upload file
const mirror = s.getAttribute("data-mirror") || false; //mirror the boundary boxes
const scoreThreshold = s.getAttribute("data-scoreThreshold") || 0.5;
const apiServer = window.location.origin + '/recognition'; //the full TensorFlow Object Detection API server url

//Video element selector
v = document.getElementById(sourceVideo);

//for starting events
let isPlaying = false,
    gotMetadata = false;

//Canvas setup

//create a canvas to grab an image for upload
let imageCanvas = document.createElement('canvas');
let imageCtx = imageCanvas.getContext("2d");

//create a canvas for drawing object boundaries
let drawCanvas = document.createElement('canvas');
document.body.appendChild(drawCanvas);
let drawCtx = drawCanvas.getContext("2d");

//draw boxes and labels on each detected object
function drawFaces(faces) {

    //clear the previous drawings
    drawCtx.clearRect(0, 0, drawCanvas.width, drawCanvas.height);

    //console.log(faces.length);
    for (var f in faces) {
        
        // https://www.codeseek.co/huningxin/opencv-js-face-detection-EvmMYN
        x = faces[f].Pos_0 - 320
        y = faces[f].Pos_1 - 190
        w = faces[f].Pos_2 - 680
        h = faces[f].Pos_3 - 590

        console.log([x, y]);
        console.log([w, h]);

        //drawCtx.lineWidth = 3;
        //drawCtx.strokeStyle = color;
        //drawCtx.strokeRect(x, y, w, h);
        drawCtx.fillText(faces[f].face + " - " + Math.round(faces[f].probabilidade * 100) + "%", x + 5, y + 20);
        //drawCtx.strokeRect(x, y, width, height);
    }

}

//Add file blob to a form and post
function postFile(file) {

    $('.status-reconhecimento').html('Movimento detectado, analisando frame...');

    //Set options as form data
    let formdata = new FormData();
    formdata.append("frame", file);
    formdata.append("threshold", scoreThreshold);

    let xhr = new XMLHttpRequest();
    xhr.open('POST', apiServer, true);
    xhr.onload = function () {
        if (this.status === 200) {
            console.log(this.response);
            let faces = JSON.parse(this.response);

            $('.status-reconhecimento').html('');
            //console.log(faces.length)
            if( faces.length > 0 ){
                
                //draw the faces
                //drawFaces(faces);
                // Dados do paciente reconhecido...
                paciente = faces[0];
                if( paciente.face != 'Desconhecido' ){
                    $('.paciente-nome').html('Ol&aacute;, '+paciente.face);
                    $('.paciente-recog').html('<li>Probabilidade: ' + (paciente.probabilidade*100)+ '%</li>' +
                                              '<li>L2: ' + paciente.L2+ '</li>' +
                                              '<li>uM: ' + paciente.uM+ '</li>');
                }else{

                    console.log('Paciente desconhecido...');
                    $('.paciente-nome').html('( Desconhecido )');
                    //setTimeout(function(){
                        
                    $('.paciente-recog').html('O próximo módulo do Francis será capaz de cadastrar novas faces de modo automático. :)');
                    setTimeout(function(){
                        
                        $('.paciente-recog').html('Além disso, será possível fazer seu reconhecimento através da sua carteira de plano de saúde ou RG! ;D');
                        setTimeout(function(){
                            $('.paciente-nome').html('( AGUARDANDO )');
                            $('.paciente-recog').html('');
                        }, 2500);

                    }, 3000);

                    //}, 4000);
                    
                }
            }else{
                $('.paciente-nome').html('( AGUARDANDO )');
                $('.paciente-recog').html('');
            }

            //Save and send the next image
            imageCtx.drawImage(v, 0, 0, v.videoWidth, v.videoHeight, 0, 0, uploadWidth, uploadWidth * (v.videoHeight / v.videoWidth));
            imageCanvas.toBlob(postFile, 'image/jpeg');
        }
        else {
            console.error(xhr);
        }
    };
    xhr.send(formdata);
}

//Start object detection
function startObjectDetection() {

    //console.log("starting object detection");

    //Set canvas sizes base don input video
    drawCanvas.width = v.videoWidth;
    drawCanvas.height = v.videoHeight;

    imageCanvas.width = uploadWidth;
    imageCanvas.height = uploadWidth * (v.videoHeight / v.videoWidth);

    //Some styles for the drawcanvas
    drawCtx.lineWidth = 4;
    drawCtx.strokeStyle = "cyan";
    drawCtx.font = "20px Verdana";
    drawCtx.fillStyle = "cyan";

    //Save and send the first image
    imageCtx.drawImage(v, 0, 0, v.videoWidth, v.videoHeight, 0, 0, uploadWidth, uploadWidth * (v.videoHeight / v.videoWidth));
    imageCanvas.toBlob(postFile, 'image/jpeg');

}

//Starting events

//check if metadata is ready - we need the video size
v.onloadedmetadata = () => {
    //console.log("video metadata ready");
    gotMetadata = true;
    if (isPlaying)
        startObjectDetection();
};

//see if the video has started playing
v.onplaying = () => {
    //console.log("video playing");
    isPlaying = true;
    if (gotMetadata) {
        startObjectDetection();
    }
};