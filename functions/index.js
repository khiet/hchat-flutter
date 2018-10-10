const functions = require('firebase-functions');

const cors = require('cors')({ origin: true });
const Busboy = require('busboy');
const os = require('os');
const path = require('path');
const fs = require('fs');
const fbAdmin = require('firebase-admin');
const uuid = require('uuid/v4');

const gcconfig = {
  projectId: 'hchat-app',
  keyFilename: 'hchat-app-firebase-adminsdk.json'
};

const gcs = require('@google-cloud/storage')(gcconfig);

fbAdmin.initializeApp({
  credential: fbAdmin.credential.cert(
    require('./hchat-app-firebase-adminsdk.json')
  )
});

exports.storeImage = functions.https.onRequest((req, res) => {
  return cors(req, res, () => {
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
      const bucket = gcs.bucket('hchat-app.appspot.com');
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
    return busboy.end(req.rawBody);
  });
});
