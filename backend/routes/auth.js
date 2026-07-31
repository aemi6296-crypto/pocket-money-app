const express = require('express');
const router = express.Router();
const { admin, db } = require('../config/firebase');

router.post('/signup', async (req, res) => {
  const { email, password, role, fullName } = req.body;

  if (!email || !password || !role) {
    return res.status(400).json({
      message: 'Email, password and role are required'
    });
  }

  try {
    
    const user = await admin.auth().createUser({
      email,
      password,
    });

   
    await db.collection('users').doc(user.uid).set({
      email,
      role,
      fullName: fullName || '',
      createdAt: new Date()
    });

    
    await db.collection('wallets').doc(user.uid).set({
      balance: 0,
      ownerId: user.uid,
      currency: 'USD',
      createdAt: new Date()
    });

    res.status(201).json({
      message: 'Signup successful 🎉',
      uid: user.uid
    });

  } catch (error) {
    res.status(500).json({
      message: 'Signup failed ❌',
      error: error.message
    });
  }
});


router.post('/login', async (req, res) => {
  const { token } = req.body;

  if (!token) {
    return res.status(400).json({ message: 'Token is required' });
  }

  try {
    
    const decodedToken = await admin.auth().verifyIdToken(token);
    const uid = decodedToken.uid;

    
    const userDoc = await db.collection('users').doc(uid).get();

    if (!userDoc.exists) {
      return res.status(404).json({
        message: 'User profile not found'
      });
    }

    const userData = userDoc.data();

    res.status(200).json({
      message: 'Login successful ✅',
      uid,
      role: userData.role,
      fullName: userData.fullName
    });

  } catch (error) {
    res.status(401).json({
      message: 'Invalid or expired token ❌',
      error: error.message
    });
  }
});

module.exports = router;

