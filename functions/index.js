const functions = require('firebase-functions');

const admin = require('firebase-admin');
admin.initializeApp();

const gcs = require('@google-cloud/storage');
const cors = require('cors');
const Busboy = require('busboy');
const os = require('os');
const path = require('path');
const fs = require('fs');
const uuid = require('uuid/v4');

const FirebaseFirestore = require('@google-cloud/firestore');

exports.writeHistory = functions.firestore
  .document('rooms/{roomID}/chats/{chatID}')
  .onCreate((snapshot, context) => {
    const firestore = new FirebaseFirestore.Firestore();

    // 1. extract roomID from Chat
    const roomID = context.params.roomID;
    // 2. construct history from Chat
    const createdChat = snapshot.data();
    const chatCreatedAt = new FirebaseFirestore.Timestamp(
      createdChat['createdAt']['_seconds'],
      createdChat['createdAt']['_nanoseconds']
    );
    const chatPreviewText = createdChat['text'] ? createdChat['text'] : createdChat['username'] + ' sent an image.';
    console.log('chatPreviewText: ' + chatPreviewText);
    const historyData = {
      'roomID': roomID,
      'lastChatPreviewText': chatPreviewText,
      'lastChatUsername': createdChat['username'],
      'lastChatPartnerName': createdChat['partnerName'],
      'lastChatCreatedAt': chatCreatedAt,
      'userIDs': [createdChat['userID'], createdChat['partnerID']]
    };

    const historyPromise = firestore.collection('histories')
      .where('roomID', '==', roomID)
      .get()
      .then(historyQs => {
        if (historyQs.empty) {
          return firestore.collection('histories').add(historyData);
        } else {
          return historyQs.docs[0].ref.set(historyData);
        }
      });

    return Promise.all([historyPromise]);
  });

exports.storeImage = functions.https.onRequest((req, res) => {
  return cors({ origin: true })(req, res, () => {
    if (req.method !== 'POST') {
      return res.status(500).json({ message: 'Internal Server Error' });
    }

    const busboy = new Busboy({ headers: req.headers });
    let uploadData;
    let oldImagePath;

    busboy.on('file', (fieldname, file, filename, encoding, mimetype) => {
      const filePath = path.join(os.tmpdir(), filename);
      uploadData = {
        filePath: filePath,
        type: mimetype,
        name: filename
      };
      file.pipe(fs.createWriteStream(filePath));
    });

    busboy.on('field', (fieldname, value) => {
      oldImagePath = decodeURIComponent(value);
    });

    busboy.on('finish', () => {
      const bucket = gcs().bucket('hchat-app.appspot.com');
      const downloadToken = uuid();
      let imagePath = 'images/' + downloadToken + '-' + uploadData.name;
      if (oldImagePath) {
        imagePath = oldImagePath;
      }

      return bucket.upload(uploadData.filePath, {
        uploadType: 'media',
        destination: imagePath,
        metadata: {
          metadata: {
            contentType: uploadData.type,
            firebaseStorageDownloadTokens: downloadToken
          }
        }
      }).then(() => {
        return res.status(201).json({
          imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/' +
            bucket.name +
            '/o/' +
            encodeURIComponent(imagePath) +
            '?alt=media&token=' +
            downloadToken,
          imagePath: imagePath
        });
      });
    });

    // https://stackoverflow.com/questions/47327777/firebase-functions-returns-and-promises-do-not-exit-the-function
    // Cloud Functions triggered by HTTP requests need to be terminated by ending them with
    // a send(), redirect(), or end(), otherwise they will continue running and reach the timeout.
    return busboy.end(req.rawBody);
  });
});