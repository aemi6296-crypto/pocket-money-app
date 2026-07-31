const express = require('express');
const router = express.Router();
const { db } = require('../config/firebase');


router.post('/save-token', async (req, res) => {
  const { uid, fcmToken } = req.body;

  if (!uid || !fcmToken) {
    return res.status(400).json({ message: 'uid and fcmToken are required' });
  }

  try {
    await db.collection('users').doc(uid).set(
      { fcmToken },
      { merge: true }
    );

    res.status(200).json({ message: 'Token saved ✅' });

  } catch (error) {
    res.status(500).json({ message: 'Failed to save token ❌', error: error.message });
  }
});

module.exports = router;
